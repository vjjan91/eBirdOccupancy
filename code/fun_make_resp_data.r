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
  df <- filter(df, p_value <= 0.05 | predictor == "Int" | is.na(modulator))
  
  intercept <- dplyr::filter(df, predictor == "Int") %>% .$coefficient
  
  df <- dplyr::mutate(df, 
               data = purrr::map2(predictor, modulator, function(x,m){
                 # make a seq of x values
                 seq_x <- rep(seq(0,1, 0.1), 10)
                 coefficient_x <- dplyr::filter(df, 
                                                predictor == x,
                                                is.na(modulator)) %>% .$coefficient
                 
                 # check if there is a modulator
                 if(!is.na(m)) {
                   # make a seq of m values and get coefficient
                   seq_m <- rep(seq(0,1, 0.1), 10)
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
                 # calculate y
                 y <- intercept + (coefficient_x*seq_x) + 
                   (coefficient_m*seq_m) +
                   (coefficient_inter*(seq_x*seq_m))
                 y <- 1/(1 + exp(-y))
                 
                 # make data frame
                 data_resp <- tibble::tibble(seq_x, seq_m, y)
                 # make groups of the modulator
                 data_resp <- dplyr::mutate(data_resp,
                                     m_group = cut(seq_m, breaks = 2))
                 return(data_resp)
               }))
  # now filter again on p_value
  df <- filter(df, p_value <= 0.05, predictor != "Int")
  return(df)
}
