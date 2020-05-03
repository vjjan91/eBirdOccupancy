### code-23-Extracting model coefficients for best supported hypothesis ###

# Load necessary libraries
library(openxlsx)
library(tidyverse)
library(tidyselect)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)

# functions to wrangle models
source("code/fun_model_estimate_collection.r")
source("code/fun_make_resp_data.r")

# read in the excel sheet containing information on the best supported hypothesis
sheet_names <- readxl::excel_sheets("data/results/all_hypoComparisons_allScales.xlsx")
which_sheet <- which(str_detect(sheet_names, "Best"))

hypothesis_data <- readxl::read_excel("data/results/all_hypoComparisons_allScales.xlsx",
                                      sheet = sheet_names[which_sheet])

# Subsetting the data needed to call in each species' model coefficient information
hypothesis_data <- select(hypothesis_data,
                          Scientific_name, Common_name,
                          contains("Best supported hypothesis"))

# pivot longer
hypothesis_data <- pivot_longer(hypothesis_data,
                                cols = contains("Best"),
                                names_to = "scale", values_to = "hypothesis")
# fix scale to numeric
hypothesis_data <- mutate(hypothesis_data,
                          scale = if_else(str_detect(scale, "10"), "10km", "2.5km"))

# list the supported hypotheses
# first separate the hypotheses into two columns
hypothesis_data <- separate(hypothesis_data, col = hypothesis, sep = "; ", 
                            into = c("hypothesis_01", "hypothesis_02"),
                            fill = "right") %>% 
  # then get the data into long format
  pivot_longer(cols = c("hypothesis_01","hypothesis_02"),
               values_to = "hypothesis") %>% 
  # remove NA where there is only one hypothesis
  drop_na() %>% 
  # remove the name column
  select(-name)

# correct the name landCover to lc
hypothesis_data <- mutate(hypothesis_data,
                          hypothesis = replace(hypothesis,
                                               hypothesis %in% c("landCover", "climate",
                                                                 "elevation"), 
                                               c("lc","clim","elev")))

# which file to read model estimates from
hypothesis_data <- mutate(hypothesis_data,
                          file_read = glue::glue('data/results/results_model_est_{scale}/{hypothesis}_modelEst.xlsx'))

# read in data as list column
model_data <- mutate(hypothesis_data,
                     model_est = map2(file_read, Scientific_name, function(fr, sn){
                       readxl::read_excel(fr, sheet = sn)
                     }))

# rename model data components and separate predictors
names <- c("predictor", "coefficient", "se", "ci_lower", "ci_higher", "z_value", "p_value")

# get data for plotting
model_data <- mutate(model_data, 
                     model_est = map(model_est, function(df){
  colnames(df) <- names
  df <- separate_interaction_terms(df)
  df <- make_response_data(df)
  return(df)
}))

# keep significant predictors
model_data <- model_data[map_int(model_data$model_est, nrow) > 0,]

# this data is ready to plot
