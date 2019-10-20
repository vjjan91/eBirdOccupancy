

### Loading the land cover rasters (resampled at diferent resolutions)

library(raster)
# THIS HAS BEEN CHANGED TO SUIT THE EXAMPLE, REPLACE WITH CORRECT LC RASTER
rast_10m <- raster("data/spatial/landcover100m.tif")
# plot(rast_10m)
# rast_10m

## From Matthew-strimas - eBird code 

# The simplest metric of landscape composition is the percentage of the landscape in 
# each land cover class (PLAND in the parlance of FRAGSTATS). For a broad range of scenarios, 
# PLAND is a reliable choice for calculating habitat covariates in distribution modeling. 
# Based on our experience working with eBird data, an approximately 2.5 km by 2.5 km neighborhood (5 by 5 MODIS cells) 
# centered on the checklist location is sufficient to account for the spatial precision in the data when 
# the maximum distance of travelling counts has been limited to 5 km, while being a relevant ecological scale for many bird species.

### NOTE: Might want to find a measure of landscape configuration as well?? ##

# Setting a radius of 2.5km * 2.5 km as suggested above
# THIS HAS BEEN CHANGED TO SUIT THE EXAMPLE
neighborhood_radius <- 50 * ceiling(max(res(rast_10m))) / 2

# Load eBird data prepared by PG so far
# Loading the dataset containing 10 random observations made to a site file

library(data.table)
# reading 1e2 rows --- THIS IS AN EXAMPLE, REMOVE NROWS FOR FULL DATA
dat <- fread("data/dataRand10.csv",header=T, nrows = 1e2)
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

# make velox object
lc_velox = velox(rast_10m)

# extract values from velox
lcvals = lc_velox$extract(sp = ebird_buff, df=T)
names(lcvals) = c("id", "lc")

# get spread proportions
library(glue); library(stringr)
lc_prop = count(lcvals, id, lc) %>% 
  group_by(id) %>%
  mutate(lc = glue('lc_{str_pad(lc, 2, pad = "0")}'), 
    prop = n/sum(n)) %>% 
  dplyr::select(-n) %>% 
  tidyr::pivot_wider(names_from = lc, 
                     values_from = prop)
  
# link back to rand10 via ebird buff using coordinate id
# drop geometry and assign id column
ebird_buff <- ebird_buff %>% 
  st_drop_geometry() %>% 
  mutate(id = 1:nrow(.)) %>% 
  # merge on id
  left_join(lc_prop, by = "id")

# join to rand10 on locality id
dat <- dat %>% 
  left_join(ebird_buff, by = "locality_id")

# WRITE DAT AS PREFERRED
fwrite(dat, file = "data/dataRand10_withLC.csv")

# ends here