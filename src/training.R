
#--- load environment ---------------------------------
gc()
setwd("~/workspace/chaordic-challenge/src")

library(data.table)
library(tidyverse)
library(lubridate)

source("utils.R")


#--- read training files ---------------------------------

dt_views <- c("../data/pdpviews-Dez05-sample.ndjson",
              "../data/pdpviews-Dez06-sample.ndjson") %>% 
                   map(read_and_treat_jsonfile) %>% 
                   bind_rows()


setDT(dt_views, key="user_id")
dt_views[, timestamp:=ymd_hms(timestamp)]
dt_views[, period:=sapply(timestamp, get_day_period)]
dt_views[, price_range:=sapply(price, get_price_range)]

# temporary dt_views_dummy
dt_views_dummy <- dt_views

#--- set up global constants -------------------------------

# range of the features
price_range <- dt_views[, diff(range(price_range))]
views_range <- dt_views[, .N, user_id][, diff(range(N))]
period_range <- dt_views[, diff(range(period))]
# to avoid bug of all data be in the same period
period_range <- ifelse(period_range==0, 1, period_range)

dummmy_thrs_views <- 10
max_recomendations <- 15
thrs_pricediff <- 1

CONSTANTS <-list(price_range=price_range, views_range=views_range, period_range=period_range, 
                 dummmy_thrs_views=dummmy_thrs_views, max_recomendations=max_recomendations)
saveRDS(CONSTANTS, "./cache/constants.rds")

#--- read test file -----------------------------------------

source("load-testset.R")


#--- test performance of params combination -----------------

params <- list(n_dummies=c(100, 250, 500, 1000), thrs_price=c(0.25, 0.5, 1, 1.5))
params_grid <- expand.grid(params$n_dummies, params$thrs_price)
names(params_grid) <- c("n_dummies", "thrs_price")

evaluations <- list()
for( i in 1:nrow(params_grid)){

        thrs_pricediff <- params_grid$thrs_price[i]

        # training the model                
        dummy_profiles <- create_dummy_profiles(params_grid$n_dummies[i], dummmy_thrs_views)
        recs <- lapply(transactionis_users_test, recommend_product)
        
        evaluations[[paste0("e", i)]] <- evaluate_recommender_system(recs)
        print( rbindlist(evaluations))
}

evaluations <- rbindlist(evaluations)
evaluations <- evaluations %>% 
                        mutate(param=paste0("p", 1:nrow(evaluations))) %>% 
                        mutate(F_score=2*precision*recall/(precision+recall))
saveRDS(evaluations, "./cache/evaluations.rds")

evaluations %>% 
        mutate_at(1:2, ~.x*100) %>% 
        ggplot2::ggplot(aes(x=recall, y=precision)) + 
                geom_point(size=3) +
                geom_text(aes(label=param), hjust=-0.5, vjust=1, size=3) +
                scale_x_continuous(limits=c(0, 45)) +
                scale_y_continuous(limits=c(0, 45)) +
                labs(x="Recall (%)", y="Precision (%)") +
                theme_bw()


# --- creating the model with the best params -----------------

# best params
param_id <- evaluations %>% with(which.max(F_score))
saveRDS(params_grid[param_id,], "./cache/best-params.rds")

thrs_pricediff <- params_grid$thrs_price[param_id]
n_dummies <- params_grid$n_dummies[param_id]
dummy_profiles <- create_dummy_profiles(n_dummies, dummmy_thrs_views)
saveRDS(dummy_profiles, "./cache/dummy-profiles.rds")

dt_views_dummy <- dt_views[dummy_profiles$user_id]
saveRDS(dt_views_dummy, "./cache/dt-views-dummy.rds")


