#### dataprep round 2 ####

rm(list = ls()); gc()

#'load libs
library(tidyverse); library(readr)

#'load csv from data folder
data = read_csv("data/dataCovars.csv") #%>%
#  filter(!is.na(rptrScore))

#### subset 10 random obs per locality per species ####
#'split into list by species, locality id, and sample 10 if > 10 samples found
#'sampling WITHOUT replacement by default, now explicit in code
dataSubsample = data %>% 
  plyr::dlply(c("scientific_name", "locality_id")) %>% 
  map_if(function(x) nrow(x) > 10, function(x) sample_n(x, 10, replace = FALSE)) %>% 
  bind_rows()

#### write to file ####
write_csv(dataSubsample, path = "data/dataRand10.csv")

####clean workspace ####
rm(list = ls()); gc()
