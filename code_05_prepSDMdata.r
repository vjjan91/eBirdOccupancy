#### dataprep round 4 ####
#'in this round, get the environmental
#'covariates of locality ids for each species
#'

#### load libs ####
library(tidyverse); library(readr)

#### load data covars ####
#'load environment covariates from csv
dataCovar = read_csv("data/dataCovars.csv")

# load wide data
load("dataSpread.rdata")

#'keep only distinct locality ids, remove fields related to observation
#'define field to keep
fieldsToKeep = c("locality", "locality_id", "locality_type",
                 "longitude", "latitude", "elevation",
                 "evi.Jan", "evi.Feb", "evi.Mar", "evi.Apr",
                 "evi.May", "evi.Jun", "evi.Jul", "evi.Aug",
                 "evi.Sep", "evi.Oct", "evi.Nov", "evi.Dec",
                 "slope", "aspect", "expertise")

#'keep the fields specified
dataCovar = distinct(dataCovar, locality_id, .keep_all = T) %>% 
  select(fieldsToKeep)

#### join with presence and absence data ####

#'join with dataframe of presences and absences
#'if a combined dataframe is the objective, do this
dataPresAbsCovars = dataSpread[["Ficedula nigrorufa"]][["pres_abs"]] %>% 
  left_join(dataCovar, by = "locality_id")

#'if a standalone dataframe without the presence data is required, do this
dataCovar = dataCovar %>% 
  filter(locality_id %in% dataSpread[["Ficedula nigrorufa"]][["pres_abs"]]$locality_id)

#### calling dataframes for functions ####
#'in general, list elements with names can be called by this notation
#'list[[first_level_name]][[second_level_name]]
#'
#'in this case, see the calling of black-and-orange flycatcher presence data
#'from the 2 level list dataSpread above
#'1. level one is the species
#'2. level two are the variables
#'
#'for a full list of all species (14 elements long), each of the
#'14 elements will have N nested sub-elements, where N is the
#'number of variables, such as presence_absence, number-of-observers etc.