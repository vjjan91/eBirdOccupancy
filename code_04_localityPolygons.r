#### identifying localities ####
#'in this code, collect unique combinations of coordinates and locality
#'then draw a 95% kde around them
#'plot in tmap/other
#'
#### load libs and data ####
#'libs
library(tidyverse); library(readr); library(sf)

#'load data
data = read_csv("data/dataCovars.csv")
#'isolate unique coord - locality triads
dataLocs = data %>% 
  distinct(longitude, latitude, locality_id, locality, locality_type)

#### filter data ####

#'take a look at the counts
localityCount = count(dataLocs, locality)
#' quite some "localities" are simply coordinate pairs
#' keep localities with 5 or more points
dataLocsMultiN = left_join(dataLocs, localityCount, by = "locality") %>% 
  filter(n >= 5)

#'split by locality
dataLocsMultiN = plyr::dlply(dataLocsMultiN, "locality")

#### draw 95% kde ####
#'load ks
library(ks)

a = as.matrix(dataLocs[,c("longitude","latitude")])
b = kmeans(a, centers = 20)

#'source raster_to_df function
source("")