#' Separate model interaction terms.
#'
#' @param model_estimate_df A dataframe of model estimates, where interaction terms are represented as x1:x2.
#'
#' @return A data frame of model estimates, with the interaction terms separated.
#' @export

separate_interaction_terms <- function(model_estimate_df){
  
  # subset for occupancy covariates
  model_estimate_df <- model_estimate_df %>%
        dplyr::mutate(has_psi = stringr::str_detect(predictor, "psi")) %>%
        dplyr::filter(has_psi) %>%
        dplyr::select(-has_psi)
        
  # now mutate a new column where 
  df <- dplyr::mutate(model_estimate_df, 
                predictor = stringr::str_extract(predictor, 
                                                 pattern = stringr::regex("\\((.*?)\\)")),
                predictor = stringr::str_replace_all(predictor, "[//(//)]", ""))
    
    pred_mod <- stringr::str_split_fixed(df$predictor, ":", 2) %>% 
      `colnames<-`(c("predictor", "modulator")) %>% 
      tibble::as_tibble() %>% 
      dplyr::mutate(modulator = dplyr::if_else(modulator == "", as.character(NA), 
                                               modulator))
    
    df <- dplyr::select(df, -predictor)
    df <- dplyr::bind_cols(pred_mod, df)
    
    return(df)
}
