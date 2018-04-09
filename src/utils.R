
read_and_treat_jsonfile <- function(path){
        
        dt_views <- read_file(path) %>% 
                        str_split("\n") %>% 
                        unlist() %>% 
                        # remove last line which is only a '\n' 
                        {`[`(., 1:(length(.)-1))} %>% 
                        # fix bug to parse null price
                        gsub(pattern="price\":null", replacement="price\":0") %>% 
                        map_df(jsonlite::fromJSON)

        # remove the null price        
        dt_views <- dt_views %>% filter(price!=0)
        dt_views
}


get_day_period <- function(timestamp){
        # class of day period
        # 0 - late night
        # 1 - morning
        # 2 - afternoon
        # 3 - night
        hour(timestamp)%/%6
}


get_price_range <- function(price){
        log(price, 2)
}


trace_user_profile <- function(u_id){
        
        dt_views[u_id, .(user_id=u_id, 
                          period=median(period), 
                          price=median(price_range),
                          views=.N
                )]
}


trace_user_product_profile <- function(u_id){
        
        dt_views[u_id, .(product_id, price_range)]
}


trace_dummy_product_profile <- function(u_id){
        
        dt_views_dummy[u_id, .(product_id, price_range)]
}


compute_profiles_distances <- function(profile_1, profile_2){
        
        period_diff <- profile_1$period - profile_2$period
        price_diff <- profile_1$price - profile_2$price
        views_diff <- profile_1$views - profile_2$views
        
        period_effect <- abs(period_diff)/period_range
        price_effect <- abs(price_diff)/price_range
        views_effect <- abs(views_diff)/views_range
        
        users_distance <- 0.5*price_effect + 0.3*period_effect + 0.2*views_effect
        users_distance
}


compute_users_distance <- function(user_1, user_2){
        
        profile_1 <- trace_user_profile(user_1)
        profile_2 <- trace_user_profile(user_2)
        
        compute_profiles_distances(profile_1, profile_2)
}


create_dummy_profiles <- function(dummy_numbers, dummy_thrs){
        
        set.seed(10)
        dummy_users <- dt_views[, .N, user_id][N >= dummy_thrs, sample(user_id, dummy_numbers)]
        
        dummy_profiles <- rbindlist(lapply(dummy_users, trace_user_profile))
        setkey(dummy_profiles, "user_id")
        dummy_profiles
}


compute_distance_from_dummy <- function(u_id){
        
        u_profile <- trace_user_profile(u_id)
        
        dummy_dists <- c()
        for( i in 1:nrow(dummy_profiles)){
                new_dist <- compute_profiles_distances(dummy_profiles[i], u_profile)
                names(new_dist) <- dummy_profiles[i, user_id]
                dummy_dists <-c(dummy_dists, new_dist)
        }
        dummy_dists
}


recommend_product <- function(u_id){
        
        distances_from_dummies <- compute_distance_from_dummy(u_id) %>% sort()
        
        # check if u_id it's not one of the populars
        if( names(distances_from_dummies[1])==u_id){
                closer_dummy <- names(distances_from_dummies[2])
        }else{
                closer_dummy <- names(distances_from_dummies[1])
        }
        
        u_profile <- trace_user_profile(u_id)
        closer_products <- trace_dummy_product_profile(closer_dummy)
        
        closer_products[, diff_price:=abs(price_range-u_profile$price)]
        closer_products <- closer_products[order(diff_price)]
        products_recommendation <- closer_products[diff_price < thrs_pricediff, product_id]
        
        # check if at least one product was recommended by threshold judgement
        ## if not recommmend the closer one
        if( length(products_recommendation) > 0){
                if( length(products_recommendation) > max_recomendations){
                        products_recommendation <- products_recommendation[1:max_recomendations]
                }
                return( products_recommendation)
        }else{
                product_recommendation <- closer_products[1, product_id]
                return( product_recommendation)
        }
        
}


compute_recs_precision <- function(recs){
        
        recs <- unlist(recs)
        recs_in_purchases <- sum(recs %in% dt_transactions_test$product_id)
        recs_in_purchases/length(recs)
}


compute_recs_recall <- function(recs){
        
        purchase_products <- dt_transactions_test$product_id
        purchase_products_in_recs <- sum(purchase_products%in%unique(unlist(recs)))
        
        purchase_products_in_recs/length(purchase_products)
}


evaluate_recommender_system <- function(recs){
        
        precision <- compute_recs_precision(recs)
        recall <- compute_recs_recall(recs)
        
        list(precision=precision, recall=recall)
}


write_output_line <- function(u_id, recs){
        
        items_value <- paste0(paste0("'", unlist(recs), "'"), collapse=",")
        paste0("{'browser_id': '", u_id, "', 'items': [", items_value, "]}")
}

