
convert_transactions_lines_tojson <- function(line){
        
        line_json <- jsonlite::fromJSON(line)
        
        if( !is.data.frame(line_json$items)){
                line_json_treated <- c(line_json[1:4], as.list(line_json$items))
                return(line_json_treated)
        }
        
        line_json_append <- list()
        for( i in 1:nrow(line_json$items)){
                line_json_append[[i]] <- c(line_json[1:4], as.list(line_json$items[i, ])) 
        }
        return(bind_rows(line_json_append))
}


dt_transactions <- read_file("../data/transactions-Dez07.ndjson") %>% 
                        str_split("\n") %>% 
                        unlist() %>% 
                        {`[`(., 1:(length(.)-1))} %>% 
                        map_df(convert_transactions_lines_tojson)


setDT(dt_transactions, key="user_id")


transactions_all_users <- dt_transactions[, unique(user_id)]
transactionis_users_test_all <- transactions_all_users[transactions_all_users %in% dt_views$user_id]

set.seed(100)
transactionis_users_test <- sample(transactionis_users_test_all, 1000)
dt_transactions_test <- dt_transactions[user_id%in%transactionis_users_test]
setkey(dt_transactions_test, "user_id")
