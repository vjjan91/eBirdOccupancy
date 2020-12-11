library(glue)
library(stringr)

vars <- c("Temperature","Precipitation",
          "Agriculture","Forests","Plantations",
          "Settlements","Tea",
          "WaterBodies")

models <- list()

for(i in seq(length(vars))){
  vc <- combn(vars,i)
  for (j in 1:ncol(vc)){
    seq_i <- seq(i)
    model <- as.formula(paste0("logit(psi)","~", paste0(seq_i,"*",vc[,j], collapse = " + ")))
    
    # process it a bit more
    model <- as.character(model)
    
    model <- stringr::str_c(model[2], model[1], model[3], sep = " ")
    
    # get named replacement vector
    replacements <- as.character(glue('β_{seq_i}'))
    names(replacements) <- as.character(seq_i)
    
    # replace NULLs
    model <- str_replace_all(model, replacements)
  
    
    models <- c(models, model)
  }
}
