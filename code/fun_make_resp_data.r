#' Get response data from single and interaction predictors.
#'
#' @param df A data frame of predictor coefficients; may include interaction terms.
#'
#' @return A data frame with a list column of y values as a response to predictors and/or modulators.
#' @export
#' @import magrittr
make_response_data <- function(df){
  # df <- dplyr::filter(df, p_value <= 0.05 | predictor == "Int")
  # keep all single predictors, Intercept, and interactions with significant p_val
  
  # define internal function
  ci <- function(x){qnorm(0.975)*sd(x, na.rm = TRUE)/sqrt(length(x))}
  
  df <- filter(df, p_value <= 0.05 | predictor == "Int" | is.na(modulator))
  
  intercept <- dplyr::filter(df, predictor == "Int") %>% .$coefficient
  
  # swap predictor and modulator if modulator exists and predictor is elevation
  df <- dplyr::mutate(df,
                      tmp_modulator = dplyr::if_else(predictor == "alt.y" &
                                                !is.na(modulator), 
                                              true = "alt.y",
                                              false = as.character(NA)))
  
  df <- dplyr::mutate(df,
                      tmp_predictor = dplyr::if_else(predictor == "alt.y" &
                                                       !is.na(modulator), 
                                                     true = modulator,
                                                     false = predictor))
  df <- dplyr::mutate(df,
                      modulator = tmp_modulator,
                      predictor = tmp_predictor) %>% 
    select(-contains("tmp"))
  
  df <- dplyr::mutate(df, 
                      predictor_scale = case_when(
                        predictor == "alt.y" ~ 2625,
                        stringr::str_detect(predictor, "lc") == T ~ 1,
                        stringr::str_detect(predictor, "prec") == T ~ 300,
                        stringr::str_detect(predictor, "temp") == T ~ 50,
                        stringr::str_detect(predictor, "17") == T ~ 80,
                        stringr::str_detect(predictor, "18") == T ~ 300,
                        TRUE ~ 1
                      ),
                      modulator_scale = case_when(
                        modulator == "alt.y" ~ 2625,
                        stringr::str_detect(predictor, "lc") == T ~ 1,
                        stringr::str_detect(predictor, "prec") == T ~ 300,
                        stringr::str_detect(predictor, "temp") == T ~ 50,
                        stringr::str_detect(predictor, "17") == T ~ 80,
                        stringr::str_detect(predictor, "18") == T ~ 300,
                        TRUE ~ 1
                      ))
  df <- dplyr::mutate(df,
                      data = purrr::pmap(list(predictor, predictor_scale,
                                              modulator, modulator_scale), 
                                         function(x,x_scale,m,m_scale){
                 
                 # make a seq of x values
                 seq_x <- seq(0, 1, length.out = 10)
                 # get coeff values
                 coefficient_x <- dplyr::filter(df, 
                                                predictor == x,
                                                is.na(modulator)) %>% .$coefficient
                 
                 # check if there is a modulator
                 if(!is.na(m)) {
                   # make a seq of m values and get coefficient
                   seq_m <- seq(0, 1, length.out = 10)
                   coefficient_m <- dplyr::filter(df, 
                                                  predictor == m,
                                                  is.na(modulator)) %>% .$coefficient
                   coefficient_inter <- dplyr::filter(df, 
                                                      predictor == x,
                                                      modulator == m) %>% .$coefficient
                 }
                 else {
                   seq_m <- 0
                   coefficient_m <- 0
                   coefficient_inter <- 0
                 }
                 # make x and m combination df
                 data_resp <- tidyr::crossing(seq_x, seq_m)
                 # calculate y
                 data_resp <- mutate(data_resp,
                                    y  = intercept + 
                                      (coefficient_x*seq_x) + 
                                      (coefficient_m*seq_m) +
                                      (coefficient_inter*(seq_x*seq_m)),
                                    y = 1/(1 + exp(-y)))
                 
                 # make groups of the modulator
                 data_resp <- dplyr::mutate(data_resp,
                                            seq_m = seq_m*m_scale,
                                            seq_x = seq_x*x_scale,
                                            m_group = cut(seq_m, breaks = 2))
                 
                 # group by modulator group and summarise
                 data_resp <- data_resp %>% 
                   group_by(m_group, seq_x) %>% 
                   summarise_at(vars(y), list(mean=mean, ci=ci))
                 return(data_resp)
               }))
  # now filter again on p_value
  df <- filter(df, p_value <= 0.05, predictor != "Int")
  return(df)
}
