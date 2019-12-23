
#### Loading the land cover rasters (resampled at diferent resolutions) ####

library(raster)
rast_10m <- raster("E:\\Chapter 2_Occupancy Modeling\\Data\\Land Cover Data\\Reprojected Image_UTM43N_31stAug_Ghats.tif")
plot(rast_10m)
rast_10m

## From Matthew-strimas - eBird code 

# "The simplest metric of landscape composition is the percentage of the landscape in 
# each land cover class (PLAND in the parlance of FRAGSTATS). For a broad range of scenarios, 
# PLAND is a reliable choice for calculating habitat covariates in distribution modeling. 
# Based on our experience working with eBird data, an approximately 2.5 km by 2.5 km neighborhood (5 by 5 MODIS cells) 
# centered on the checklist location is sufficient to account for the spatial precision in the data when 
# the maximum distance of travelling counts has been limited to 5 km, while being a relevant ecological scale for many bird species"

### NOTE: Might want to find a measure of landscape configuration as well?? ##

# Setting a radius of 2.5km * 2.5 km as suggested above

neighborhood_radius <- 500* ceiling(max(res(rast_10m))) / 2

# Load eBird data prepared by PG so far
# Loading the dataset containing 10 random observations made to a site file
library(data.table)
dat <- fread("E:\\Chapter 2_Occupancy Modeling\\Data\\data_R10.csv",header=T)
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
lc_velox  <- velox(rast_10m)

lcvals <- lc_velox$extract(sp = ebird_buff, df=T)
names(lcvals) <- c("id", "lc")

# get spread proportions
library(glue)
library(stringr)
lc_prop <- count(lcvals, id, lc) %>% 
  group_by(id) %>%
  mutate(lc = glue('lc_{str_pad(lc, 2, pad = "0")}'), 
         prop = n/sum(n)) %>% 
  dplyr::select(-n) %>% 
  tidyr::pivot_wider(names_from = lc, 
                     values_from = prop,
                     values_fill = list(prop = 0)) # When a land cover class is not present within the vicinity of 2.5km, a 0 is added

# Link back to rand10 via ebird buff using coordinate id
# Drop geometry and assign id column

ebird_buff <- ebird_buff %>% 
  st_drop_geometry() %>% 
  mutate(id = 1:nrow(.)) %>% 
  # merge on id
  left_join(lc_prop, by = "id")

# join to rand10 on locality id
dat <- dat %>% 
  left_join(ebird_buff, by = "locality_id")


#### Adding other associated predictors within a radius of 2.5km by 2.5km 

library(data.table)
library(raster)
library(velox)
library(sf)

# Loading only those predictors that have a correlation of <0.7 with one another

# CHELSA Data for bio_4, bio_17, bio_18, Interannual_temp, Interannual_Precip
rasterFiles <- list.files("E:\\Chapter 2_Occupancy Modeling\\Data\\CHELSA\\", full.names = TRUE, pattern = ".tif")

# Gather resolutions
reslist <- purrr::map_dbl(rasterFiles, function(chr){
  a <- raster(chr)
  resval <- ceiling(max(raster::res(a)))
  return(resval)
})

# Load EVI Rasters for January, July and October across the 6 years
eviData <- raster::stack("E:\\Chapter 2_Occupancy Modeling\\Data\\EVI\\MOD13Q1_EVI_AllYears_2013to2018.tif")[[c(1,7,10)]]

# Gather CHELSA rasters
chelsaData <- purrr::map(rasterFiles, function(chr){
  a <- raster(chr)
  crs(a) <- crs(eviData)
  return(a)
})

# Stack CHELSA data
chelsaData <- raster::stack(chelsaData)

# Load Elevation related rasters
library(sf)
hills <- st_read("E:\\Chapter 2_Occupancy Modeling\\Data\\Shapefiles\\Nil_Ana_Pal.shp")

clip_area <- st_read("E:\\Chapter 2_Occupancy Modeling\\Data\\Shapefiles\\clip_area.shp")

elevData <- raster("E:\\Chapter 2_Occupancy Modeling\\Data\\Elevation\\WesternGhats_SRTM_Occu.tif")
alt.hills <- raster::crop(elevData, raster::extent(as(clip_area, "Spatial")))

slopeData <- terrain(x = alt.hills, opt = c("slope", "aspect"))

# Stack elevation data
elevData <- raster::stack(alt.hills, slopeData)

# Load 1km landcover data for reference (which was resampled from the 30m classification made by VR with assistance from Arasu)
lc <- raster("E:\\Chapter 2_Occupancy Modeling\\Data\\Land Cover Data\\landcover1km.tif")

# Reproject data
eviData <- projectRaster(from = eviData, to = lc, res = res(lc))
chelsaData <- projectRaster(from = chelsaData, to = lc, res = res(lc))
elevData <- projectRaster(from = elevData, to = lc, res = res(lc))

# Setting a radius of 2.5km * 2.5 km as suggested above
neighborhood_radius 

# Creating a buffer around every unique localityID, latitude and longitude
library(dplyr)

#### Run velox procedure across rasters ####

ebird_buff <- dat %>% 
  distinct(locality_id, latitude, longitude) %>% 
  # convert to spatial features
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% 
  # transform to modis projection
  st_transform(crs = projection(rast_10m)) %>% 
  # buffer to create neighborhood around each point
  st_buffer(dist = neighborhood_radius)

# Run extract across all 
env2.5kData <- purrr::map(list(eviData, chelsaData, elevData), function(stk){
  velstk <- velox(stk)
  dextr <- velstk$extract(sp = ebird_buff, df = TRUE, fun = mean)
  names(dextr) <- c("id", names(stk))
  return(as_tibble(dextr))
})

# Run a reduce leftjoin on the data
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

# Ensuring that only Traveling and Stationary checklists were considered
names(dat)
dat <- dat %>% filter(protocol_type=="Traveling" | protocol_type=="Stationary")

# We take all stationary counts and give them a distance of 100 m (so 0.1 km),
# as that's approximately the max normal hearing distance for people doing point counts.
dat <- dat %>% 
  mutate(effort_distance_km = replace(effort_distance_km, which(effort_distance_km==0 & protocol_type == "Stationary"), 0.1))

# Converting time observations started to numeric and adding it as a new column
# This new column will be minute_observations_started
dat <- dat %>%
  mutate(min_obs_started= strtoi(as.difftime(time_observations_started, format = "%H:%M:%S", units = "mins")))

# Adding the julian date to the dataframe
dat <- dat %>% mutate(julian_date = lubridate::yday(dat$observation_date))

# Removing other unnecessary columns from the dataframe and creating a clean one without the rest
names(dat)
dat.1 <- dat[,-c(1,4,5,18:35,37:41,49,50)]

# New dataframe
names(dat.1)

## Testing for correlations across the new sets of predictors
source("E:\\Chapter 2_Occupancy Modeling\\Scripts\\Pre-Processing Scripts\\screen_cor.R")
screen.cor(dat.1[,c(16:33)])

# Removing EVI for the month of Jan, bio_4 and inter-annual variation in temperature 
names(dat.1)
dat.1 <- dat.1[,c(-23,-26,-30)]

# Rename column names:
names(dat.1) <- c("duration_minutes", "effort_distance_km","locality", "locality_type",
                  "locality_id", "observer_id", "observation_date", "scientific_name", "observation_count", "protocol_type",
                  "number_observers","longitude", "latitude","pres_abs","expertise","lc_01.y", "lc_02.y", "lc_03.y",
                  "lc_04.y", "lc_05.y","lc_06.y", "lc_07.y","mean2.5k_MOD13Q1_2013to2018.7.y",
                  "mean2.5k_MOD13Q1_EVI_2013to2018.10.y","mean2.5k_CHELSA_bio10_17.y","mean2.5k_CHELSA_bio10_18.y",                       
                  "mean2.5k_CHELSA_prec_interannual_1979.2013_V1_1.y","mean2.5k_alt.y",                
                  "mean2.5k_slope.y","mean2.5k_aspect.y","min_obs_started", "julian_date")

# New column names
names(dat.1)

# WRITE DAT AS PREFERRED
fwrite(dat.1, file = "E:\\Chapter 2_Occupancy Modeling\\Data\\data_R10_withCovars_Ver4.csv")

### Trial

dat <- dat %>% 
  select(lc_)
  replace_na(0)

a  <- dat %>% filter(is.na(lc_05)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

library(mapview)
m1 <- mapview(a)

hills <- st_read("E:\\Chapter 2_Occupancy Modeling\\Data\\Shapefiles\\Nil_Ana_Pal.shp")
m2 <- mapview(elevData)
m3 <- mapview(hills)

m1+m3

