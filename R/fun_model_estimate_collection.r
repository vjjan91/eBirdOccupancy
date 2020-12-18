#' Get model estimates from top model lists or single unmarked models.
#'
#' @param list_of_top_models Either a list of the top models from model dredging, or a single unmarked model object.
#'
#' @return A two-element list, the first element is the model estimate, while the second is the relative importance of predictors.
#' The second element is only returned if the input is a list of model objects, and is NULL if the input was a single unmarked model. 
#' @export
#' @import magrittr

source("code/fun_separate_interactions.r")

get_model_estimates = function(list_of_top_models){
  
  #### handle cases where there is more than one top model ####
  if(length(list_of_top_models)>1){
    # get a  model average from the top models if not already
    if(class(list_of_top_models) != "averaging")
    {
      model_avg <- MuMIn::model.avg(list_of_top_models, fit = TRUE)
    } else {
      model_avg <- list_of_top_models
    }
    
    # get model coefficients WHY IS THIS NECESSARY
    model_coeff <- tibble::as_tibble(model_avg$coefficients,
                                     rownames = "model_type")
    
    # get the model_avg estimate
    model_estimate <- tibble::as_tibble(summary(model_avg)[["coefmat.full"]],
                                        rownames = "predictor") %>% 
      `colnames<-`(c("predictor","coefficient", "std_err", "z_value", "p_value"))
    
    # get model_avg confidence intervals
    ci_data <- tibble::as_tibble(stats::confint(model_avg), 
                                 rownames = "predictor") %>% 
      `colnames<-`(c("predictor", "ci_lower", "ci_higher"))
    
    # join ci data and model estimate
    model_estimate <- dplyr::left_join(model_estimate, ci_data)
    model_estimate <- separate_interaction_terms(model_estimate)
    
    # get the relative importance of predictors
    model_imp <- tibble::as_tibble(MuMIn::importance(model_avg),
                           rownames = "predictor")
    return_data = list(model_estimate, model_imp)
    names(return_data) = c("model_estimate", "predictor_importance")
    return(return_data)
  } 
  else {
    model <- list_of_top_models # this is really only a single unmarked model
    # get the model coefficients, WHY
    model_coeff <- unmarked::coef(model) %>% 
      tibble::as_tibble(rownames = "predictors")
    
    # get confidence intervals data
    ci_data <- purrr::map_df(c("state", "det"), function(type){
      stats::confint(model, type = type) %>% 
        tibble::as_tibble(rownames = "predictor") %>% 
        `colnames<-`(c("predictor", "ci_lower", "ci_higher"))
    })
    
    # get the model estimate
    model_estimate <- unmarked::summary(model) %>% 
      dplyr::bind_rows() %>% 
      tibble::as_tibble() %>% 
      `colnames<-`(c("coefficient", "std_err", "z_value", "p_value"))
    
    # join coeffs with confidence intervals
    model_estimate <- dplyr::bind_cols(ci_data, model_estimate)
    model_estimate <- separate_interaction_terms(model_estimate)
    
    return_data = list(model_estimate, NULL)
    names(return_data) = c("model_estimate", "predictor_importance")
    
    return(return_data)
  }
  
}

# ends here