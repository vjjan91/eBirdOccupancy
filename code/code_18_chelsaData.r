#### code extract chelsa data ####

# load libs
library(data.table)
library(raster)
library(velox)
library(sf)


#### load ebird data ####
# reading 1e2 rows --- THIS IS AN EXAMPLE, REMOVE NROWS FOR FULL DATA
dat <- fread("data/dataRand10.csv", header=T)
setDF(dat)
head(dat)

#### list raster files ####
rasterFiles <- list.files("data/chelsa/", full.names = TRUE, pattern = "crop.tif")

# gather resolutions
reslist <- purrr::map_dbl(rasterFiles, function(chr){
  a <- raster(chr)
  resval <- ceiling(max(raster::res(a)))
  return(resval)
})

# load evi data rasters
eviData <- raster::stack("data/spatial/EVI/MOD13Q1_EVI_AllYears.tif")[[c(1,7,10)]]

# gather chelsa rasters
chelsaData <- purrr::map(rasterFiles, function(chr){
  a <- raster(chr)
  crs(a) <- crs(eviData)
  return(a)
})
# stck chelsa data
chelsaData <- raster::stack(chelsaData)

# load elevation data rasters
elevData <- raster("data/elevationHills.tif")
slopeData <- terrain(x = elevData, opt = c("slope", "aspect"))
# stack elevation
elevData <- raster::stack(elevData, slopeData)

# load 1km landcover data for reference
lc <- raster("data/spatial/landcover1km.tif")

# reproject data
eviData <- projectRaster(from = eviData, to = lc, res = res(lc))
chelsaData <- projectRaster(from = chelsaData, to = lc, res = res(lc))
elevData <- projectRaster(from = elevData, to = lc, res = res(lc))


#### make buffer ####
# load data and prep buffers
# Setting a radius of 2.5km * 2.5 km as suggested above
# THIS HAS BEEN CHANGED TO SUIT THE EXAMPLE
neighborhood_radius <- 5000 * min(reslist) / 2

# Creating a buffer around every unique localityID, latitude and longitude
library(dplyr)

ebird_buff <- dat %>% 
  distinct(locality_id, latitude, longitude) %>% 
  # convert to spatial features
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% 
  # transform to modis projection
  st_transform(crs = projection(lc)) %>% 
  # buffer to create neighborhood around each point
  st_buffer(dist = neighborhood_radius)

#### run velox procedure across rasters ####
# run extract across all 
env2.5kData <- purrr::map(list(eviData, chelsaData, elevData), function(stk){
  velstk <- velox(stk)
  dextr <- velstk$extract(sp = ebird_buff, df = TRUE, fun = function(x)mean(x, na.rm=T))
  names(dextr) <- c("id", names(stk))
  return(as_tibble(dextr))
})

# run a reduce leftjoin on the data
env2.5kData <- purrr::reduce(env2.5kData, left_join)
# rename to be clear which are mean-area vars
names(env2.5kData) <- c("id", glue::glue('mean2.5k_{names(env2.5kData)[-1]}'))

#### link ebird locality to raster data ####
# link back to rand10 via ebird buff using coordinate id
# drop geometry and assign id column
ebird_buff <- ebird_buff %>% 
  st_drop_geometry() %>% 
  mutate(id = 1:nrow(.)) %>% 
  # merge on id
  left_join(env2.5kData, by = "id")

# join to rand10 on locality id
dat <- dat %>%
  left_join(ebird_buff, by = "locality_id")

# WRITE DAT AS PREFERRED
fwrite(dat, file = "data/dataRand10_with_areaMeans.csv")

# ends here
