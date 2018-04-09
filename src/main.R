
#--- load environment ---------------------------------
gc()
setwd("~/workspace/chaordic-challenge/src")

library(data.table)
library(tidyverse)
library(lubridate)

source("utils.R")


#--- load global constants -------------------------------

thrs_pricediff <- readRDS("./cache/best-params.rds")$thrs_price

CONSTANTS <- readRDS("./cache/constants.rds")
#max_recomendations <- CONSTANTS$max_recommendation
max_recomendations <- 7
price_range <- CONSTANTS$price_range
views_range <- CONSTANTS$views_range
period_range <- CONSTANTS$period_range


#--- load model constants -------------------------------

dummy_profiles <- readRDS("./cache/dummy-profiles.rds")
dt_views_dummy <- readRDS("./cache/dt-views-dummy.rds")


#--- get samples to generate output training files ---------------------------------

dt_views <- read_and_treat_jsonfile("../data/pdpviews-Dez05-sample.ndjson")
setDT(dt_views, key="user_id")
dt_views[, timestamp:=ymd_hms(timestamp)]
dt_views[, period:=sapply(timestamp, get_day_period)]
dt_views[, price_range:=sapply(price, get_price_range)]

users_samples <- dt_views[, sample(unique(user_id), 1e3)]
recs <- lapply(users_samples, recommend_product)


#--- write output -------------------------------------------------------------------

json_lines <- mapply(write_output_line, u_id=users_samples, recs=recs) %>% unname()
write(json_lines, "../recommender-output.ndjson")



