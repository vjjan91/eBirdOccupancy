

### Loading the land cover rasters (resampled at diferent resolutions)

library(raster)
rast_10m <- raster("data/landUseClassification/Reprojected Image_UTM43N_31stAug_Ghats.tif")
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

neighborhood_radius <- 500* ceiling(max(res(rast_10m))) / 2

# Load eBird data prepared by PG so far
# Loading the dataset containing 10 random observations made to a site file

library(data.table)
# reading 1e3 rows
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

# make ebird buff spatial sp from sf
ebird_buff_sp = as(ebird_buff, "Spatial")

# write function to aggregate as mode
funcMode <- function(x, na.rm = T) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# write a function 
funcPland <- function(x, na.rm = T){
  # tabulate values
  a = table(x)
  # make matrix
  a = as.matrix(a)
  # add values as rownames
  a = cbind(as.numeric(rownames(a)), a)
  # add proportions columns
  a = cbind(a, a[,2]/sum(a[,2]))
  # make vector of proportions
  v = a[,3]
  # add names
  names(v) = as.character(a[,1])
  # return named vector
  return(v)
}

# extract values from velox
lcvals = lc_velox$extract(sp = ebird_buff_sp,
                          fun = funcMode)

# not sure why ebird_buff is expected to have a list column
# suspect it should simply be a dataframe
lc_extract <- ebird_buff %>% 
  mutate(pland = lcvals)# %>% 
  # select(pland) %>% 
  # unnest(cols = pland)


