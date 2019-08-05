#### code emd over time ####

# load libs
library(data.table)
library(magrittr)
library(move)

# load data
# try for one species, say the woodpecker
data = fread("data/dataForUse.csv")[scientific_name == "Pycnonotus jocosus",]
data[,year:=year(observation_date)]

# split data by year, and convert to SPDF with say, altitude and mean evi
# get nilgiris
library(sf)
hills = st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp")
# get elev
alt = raster::raster("data/spatial/Elevation/alt/w001001.adf")
cr = raster::crop(alt, raster::extent(as(hills, "Spatial")))
alt.hills = raster::mask(cr, as(hills, "Spatial"))

# extract values at these points for data
data[,alt:=raster::extract(alt.hills, as.matrix(data[,c("longitude","latitude")]))]
data[,observation_count:=ifelse(observation_count == "X", 1, observation_count)
     ][,observation_count:=as.numeric(observation_count)
       ][,weight:=observation_count/sum(observation_count),by=year]

# now split by year and make spatial
library(dplyr); library(tidyr)
data = data %>% 
  select(weight, longitude, latitude, alt, year) %>% 
  group_by(year) %>% 
  nest()

# get ud
library(adehabitatHR)
data$ud = purrr::map(data$data, function(df){
  df = dplyr::select(df, longitude, latitude) %>% 
    st_as_sf(coords = c("longitude","latitude")) %>% 
    `st_crs<-`(4326) %>% 
    as("Spatial")
  
  ud = kernelUD(df, grid = 60)
  
  ud = getverticeshr(ud, 50)
  
})

data$raster = purrr::map(data$ud, function(ud){
  mask(alt.hills, ud)
})

# run emd
emdbird = emd(a, b)
