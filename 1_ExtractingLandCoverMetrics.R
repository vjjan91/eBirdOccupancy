

### Loading the land cover rasters (resampled at diferent resolutions)

library(raster)
rast_10m <- raster("data/landUseClassification/Reprojected Image_UTM43N_31stAug_Ghats.tif")
plot(rast_10m)
rast_10m

## From Matthew-strimas - eBird code 

# The simplest metric of landscape composition is the percentage of the landscape in 
# each land cover class (PLAND in the parlance of FRAGSTATS). For a broad range of scenarios, 
# PLAND is a reliable choice for calculating habitat covariates in distribution modeling. 
# Based on our experience working with eBird data, an approximately 2.5 km by 2.5 km neighborhood (5 by 5 MODIS cells) 
# centered on the checklist location is sufficient to account for the spatial precision in the data when 
# the maximum distance of travelling counts has been limited to 5 km, while being a relevant ecological scale for many bird species.

### NOTE: Might want to find a measure of landscape configuration as well?? ##

# Setting a radius of 2.5km * 2.5 km as suggested above

neighborhood_radius <- 500* ceiling(max(res(rast_10m))) / 2

# Load eBird data prepared by PG so far
# Loading the dataset containing 10 random observations made to a site file

library(data.table)
dat <- fread("data/dataRand10.csv",header=T)
setDF(dat)
head(dat)

# Creating a buffer around every unique localityID, latitude and longitude

library(dplyr)
library(sf)

ebird_buff <- dat %>% 
  distinct(locality_id, latitude, longitude) %>% 
  # convert to spatial features
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% 
  # transform to modis projection
  st_transform(crs = projection(rast_10m)) %>% 
  # buffer to create neighborhood around each point
  st_buffer(dist = neighborhood_radius)

## Now we will extract landcover data for every unique locality
library(velox) # Much faster than raster in terms of extracting data

# what is this function supposed to do?
calculate_pland <- function(regions,lc) {
  
  # include asserts for argument type
  # an assert looks as follows and breaks the code execution if FALSE
  # assertthat::assert_that("classname" %in% class(regions), msg = "regions has wrong class")
  
  # create a lookup table to get locality_id from row number
  locs <- st_set_geometry(regions, NULL) %>% 
    mutate(id = row_number())
  
  # extract using velox
  lc_vlx <- velox(lc)
  lc_vlx$extract(regions, df = TRUE) %>% 
    # velox doesn't properly name columns, fix that
    set_names(c("id", "landcover")) %>% 
    # join to lookup table to get locality_id
    inner_join(locs, ., by = "id") %>% 
    select(-id)
}

# Extracting landcover 
library(purrr)
library(tidyr)

lc_extract <- ebird_buff %>% 
  mutate(pland = map_df(data, calculate_pland, lc=rast_10m)) %>% 
  select(pland) %>% 
  unnest(cols = pland)


