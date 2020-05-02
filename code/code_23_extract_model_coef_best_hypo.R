### code-23-Extracting model coefficients for best supported hypothesis ###

# Load necessary libraries
library(openxlsx)
library(tidyverse)
library(tidyselect)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)

# Read in the excel sheet containing information on the best supported hypothesis
allHypoSheets <- getSheetNames("C:\\Occupancy Runs\\all_hypoComparisons_allScales.xlsx")
allHypo <-lapply(allHypoSheets,openxlsx::read.xlsx,xlsxFile="C:\\Occupancy Runs\\all_hypoComparisons_allScales.xlsx")
names(allHypo) <- allHypoSheets

# Subsetting the data needed to call in each species' model coefficient information
dat <- allHypo[[4]][c(1,2,7,8)]

# List files from folder for which you need to read in the model estimates
files <- list.files("C:\\Occupancy Runs\\Results_10km\\occuCovs\\modelEst\\",full.names=T)
basename(files)

# Store data in a list
modelEst1 <- list()
modelEst2 <- list()

for(i in 1:length(dat$Scientific_name)){
  
  if(grepl(";",dat$Best.supported.hypothesis_10km[i])==FALSE){
    
    bestHyp <- dat$Best.supported.hypothesis_10km[i]
    
    # Read in the model estimate information
    allSheets <- getSheetNames(paste("C:\\Occupancy Runs\\Results_10km\\occuCovs\\modelEst\\",
                                     bestHyp,"_modelEst.xlsx",sep = ""))
    best <-  read.xlsx(paste("C:\\Occupancy Runs\\Results_10km\\occuCovs\\modelEst\\",
                             bestHyp,"_modelEst.xlsx",sep = ""), sheet = dat$Scientific_name[i])
    names(best)[1] <- "Predictor"
  
    # Store the species-specific sheet
    modelEst1[[i]] <- best
    names(modelEst1)[i] <- dat$Scientific_name[i]
  
  } else {
    
    a <- str_split_fixed(dat$Best.supported.hypothesis_10km[i], ";", 2) %>%
      str_squish()
    tmp_list <- list()
    
    for(j in 1:length(a)){
      
      bestHyp <- a[j]

      # Read in the model estimate information
      allSheets <- getSheetNames(paste("C:\\Occupancy Runs\\Results_10km\\occuCovs\\modelEst\\",
                                       bestHyp,"_modelEst.xlsx",sep = ""))
      best <-  read.xlsx(paste("C:\\Occupancy Runs\\Results_10km\\occuCovs\\modelEst\\",
                               bestHyp,"_modelEst.xlsx",sep = ""), sheet = dat$Scientific_name[i])
      names(best)[1] <- "Predictor"
      
      # Store the species-specific sheet
      tmp_list[[j]] <- best
      names(tmp_list)[j] <- paste(dat$Scientific_name[i],"_",a[j], sep="")
    }
  modelEst2 <- append(modelEst2, tmp_list)
  }
}

# Removing NULL elements from the list of lists
modelEst1[sapply(modelEst1, is.null)] <- NULL

# Appending all lists    
all_dat <- append(modelEst1, modelEst2)    

# Write the data out:
write.xlsx(all_dat, file = "C:\\Occupancy Runs\\model_coef_Best_Hyp_10km.xlsx", rowNames=T, colNames=T)


### Get excel sheets for modulators across each species ###

## Work in Progress


# example below to be used:
# Pratik's code to get at models and modulator info:

# assuming there are multiple models in a list
mod_estimates <- clim_elev_modelEst %>%
  bind_rows() %>% 
  group_by(scientific_name) %>% # grouping and nesting by scientific name
  nest() %>% # just in case there are mix ups
  
  # now mutate a new column where 
  mutate(data = map(data, function(df){
    df = mutate(df, 
                predictor = str_extract(predictor, pattern = regex("\\((.*?)\\)")),
                predictor = str_replace_all(predictor, "[//(//)]", ""))
    
    pred_mod <- str_split_fixed(df$predictor, ":", 2) %>% 
      `colnames<-`(c("predictor", "modulator")) %>% 
      as_tibble() %>% 
      mutate(modulator = if_else(modulator == "", as.character(NA), modulator))
    
    df <- select(df, -predictor) %>% 
      bind_cols(predictors)
  }))

mod_estimates

