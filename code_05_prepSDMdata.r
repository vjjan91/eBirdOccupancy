#### dataprep round 4 ####
#'in this round, I write a function where:
#'1. I call each dataframe showing 10 random values of 6 variables for each locality
#'this is done for each species separately
#'
#'2. I get another function to get the environmental
#'covariates of locality ids for each species
#'

#### load libs ####
library(tidyverse); library(readr)

#### load data covars ####
#'load environment covariates from csv
dataCovar = read_csv("data/dataCovars.csv")

#'keep only distinct locality ids, remove fields related to observation
#'define field to keep
fieldsToKeep = c("locality", "locality_id", "locality_type",
                 "longitude", "latitude", "elevation",
                 "evi.Jan", "evi.Feb", "evi.Mar", "evi.Apr",
                 "evi.May", "evi.Jun", "evi.Jul", "evi.Aug",
                 "evi.Sep", "evi.Oct", "evi.Nov", "evi.Dec",
                 "slope", "aspect")

#'keep the fields specified
dataCovar = distinct(dataCovar, locality_id, .keep_all = T) %>% 
  select(fieldsToKeep)

