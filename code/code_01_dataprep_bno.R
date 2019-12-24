####prep data####

rm(list = ls()); gc()

#### load data from raw files ####
# load libs
library(tidyverse); library(readr); library(sf)
library(auk)
library(readxl)

# custom sum function
sum.no.na = function(x){sum(x, na.rm = T)}
# custom drop geometry function
# important note: retains coordinates but renamed to X and Y (long, lat)
dropGeometry = function(x){
  x %>% bind_cols(data.frame(st_coordinates(.))) %>% `st_geometry<-`(NULL) %>% unclass() %>% as.data.frame()
}

# add species of interest
specieslist = read_excel("data/species_list_13_11_2019.xlsx")

# set species of interest
speciesOfInterest = specieslist$scientific_name

#set file paths for auk functions
f_in_ebd <- file.path("ebd_Filtered_Jun2019.txt")
f_in_sampling <- file.path("ebd_sampling_Filtered_Jun2019.txt")

# run filters using auk packages
ebd_filters = auk_ebd(f_in_ebd, f_in_sampling) %>%
  auk_species(speciesOfInterest) %>%
  auk_country(country = "IN") %>%
  auk_state(c("IN-KL","IN-TN", "IN-KA")) %>% # Restricting geography to TamilNadu, Kerala & Karnataka
  auk_date(c("2013-01-01", "2018-12-31")) %>%
  auk_complete()

# check filters
ebd_filters

# run filters and write
# NB: this is already done, skip this step
#

f_out_ebd <- "data/eBirdDataWG_filtered.txt"
f_out_sampling <- "data/eBirdSamplingDataWG_filtered.txt"

# Below code need not be run if it has been filtered once already and the above path leads to
# the right dataset
ebd_filtered <- auk_filter(ebd_filters, file = f_out_ebd,
                           file_sampling = f_out_sampling, overwrite = TRUE)

#### read the ebird data in ####
ebd <- read_ebd(f_out_ebd)
#glimpse(ebd)

#### fill zeroes ####
zf <- auk_zerofill(f_out_ebd, f_out_sampling)
new_zf <- collapse_zerofill(zf) # Creates a new zero-filled dataframe with a 0 marked for each checklist when the bird was not observed
#   glimpse(zf)

#### remove old data ####
#rm(data, ebd_filters, ebd_subset, zf, zf_subset)

#### subset data, choose black and orange flycatcher ####
columnsOfInterest = c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed")

data = list(ebd, new_zf) %>%
  map(function(x){
    x %>% select(one_of(columnsOfInterest)) #%>%
    # filter(scientific_name %in% speciesOfInterest)
    # %>% dlply("scientific_name")
    # this above for when there are more species
  })

# remoe zerofills to save working memory
rm(zf, new_zf); gc()

# check presence and absence in absences df, remove essentially the presences df
data[[2]] = data[[2]] %>% filter(species_observed == F)

#### filter spatially ####
# load shapefiles of hill ranges
library(sf)
hills = st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp")

# write a prelim filter by bounding box
box <- st_bbox(hills)

# get data spatial coordinates
dataLocs = data %>%
  map(function(x){
    select(x, longitude, latitude) %>% 
      filter(between(longitude, box["xmin"], box["xmax"]) & between(latitude, box["ymin"], box["ymax"]))}) %>%
  bind_rows() %>%
  distinct() %>%
  st_as_sf(coords = c("longitude", "latitude")) %>%
  st_set_crs(4326) %>%
  st_intersection(hills)

# filter data by dataLocs
dataLocs = mutate(dataLocs, spatialKeep = T) %>%
  dropGeometry()

# bind to data and then filter
data = data %>%
  map(function(x){
    left_join(x, dataLocs, by = c("longitude" = "X", "latitude" = "Y")) %>%
      filter(spatialKeep == T) %>%
      select(-Id, -spatialKeep)
  })

#### presence and absence ####
# save a temp data file
save(data, file = "data.temp.rdata")

#load("data.temp.rdata")

# in the first set, replace X, for presences, with 1
data[[1]] = data[[1]] %>% 
  mutate(observation_count = ifelse(observation_count == "X", "1", observation_count))

# remove records where duration is 0
data = map(data, function(x) filter(x, duration_minutes > 0))

# group data by site and sampling event identifier
# then, summarise relevant variables as the sum
dataGrouped = map(data, function(x){
  x %>% group_by(sampling_event_identifier) %>%
    summarise_at(vars(duration_minutes, effort_distance_km, effort_area_ha), list(sum.no.na))
})

# bind rows combining data frames, and filter
dataGrouped = bind_rows(dataGrouped) %>%
  filter(duration_minutes <= 300, effort_distance_km <= 5, effort_area_ha <= 500)

# get data identifiers, such as sampling identifier etc
dataConstants = data %>% 
  bind_rows() %>% 
  select(sampling_event_identifier, time_observations_started, locality, locality_type, locality_id, observer_id, observation_date, scientific_name, observation_count, protocol_type, number_observers, longitude, latitude)

# join the summarised data with the identifiers, using sampling_event_identifier as the key
dataGrouped = left_join(dataGrouped, dataConstants, by = "sampling_event_identifier")

# remove checklists or seis with more than 10 obervers
count(dataGrouped, number_observers > 10) # count how many have 10+ obs
dataGrouped = filter(dataGrouped, number_observers <= 10)

# assign present or not, and get time in decimal hours since midnight
library(lubridate)
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}
# will cause issues if using time obs started as a linear effect and not quadratic
dataGrouped = mutate(dataGrouped, 
                     pres_abs = observation_count >= 1,
                     decimalTime = time_to_decimal(time_observations_started))

# check class of dataGrouped, make sure not sf
assertthat::assert_that(!"sf" %in% class(dataGrouped))

#### load covariates from raster files ####
# load elevation and crop to hills size, then mask by hills
#  sf
alt = raster::raster("data/spatial/Elevation/alt")
cr = raster::crop(alt, raster::extent(as(hills, "Spatial")))
alt.hills = raster::mask(cr, as(hills, "Spatial"))

# load evi layers
EVI.all = raster::stack("data/spatial/EVI/MOD13Q1_EVI_AllYears.tif")
#x11();raster::plot(EVI.all)
# scale later
# EVI.all = EVI.all*0.0001
names(EVI.all) = paste("evi", month.abb, sep = ".")

# load 5 year evi change(?) this is currently 6 years
evifiles = list.files("data/spatial/EVI", pattern = "_201", full.names = T)
evifiles = evifiles[as.numeric(stringi::stri_sub(evifiles, -8, -5)) >= 2013]

# make stack
EVI.yearly = raster::stack(as.list(evifiles))
# scale stack later
# EVI.yearly = EVI.yearly*0.0001

# resample to elevation resolution
EVI.all.resam <-  raster::resample(EVI.all, alt.hills, method ="bilinear")
EVI.yearly.resam <- raster::resample(EVI.yearly, alt.hills, method="bilinear")

# get slope and aspect
slope <- raster::terrain(alt.hills, opt = 'slope', unit='degrees', neighbors = 8)
aspect <- raster::terrain(alt.hills, opt='aspect', unit='degrees', neighbors = 8)


#### extracting raster values #####
# make raster list
landscapeRasters = list(alt.hills, EVI.all.resam, slope, aspect)

# make dataLocs sf again
dataLocs = st_as_sf(dataLocs, coords = c("X", "Y")) %>% st_set_crs(4326)

# map extract across the list
landscapeData = map(landscapeRasters, function(x){
  raster::extract(x, dataLocs)
})

# set names
names(landscapeData) = c("elevation","evi","slope","aspect")

# bind into dataframe
landscapeData = map(landscapeData, as_data_frame) %>% bind_cols() %>%
  `names<-`(c("elevation", paste("evi", month.abb, sep = "."), "slope", "aspect"))

# drop geometry of datalocs and then bind to landscape data
landscapeData = dataLocs %>% dropGeometry() %>%
  bind_cols(landscapeData)

# join with ebird data
dataCovar = left_join(dataGrouped, landscapeData, by = c("longitude" = "X", "latitude" = "Y"))

#### adding observer score ####
# read in obs score and extract numbers
expertiseScore = read_csv("data/dataObsRptrScore.csv") %>% 
  mutate(numObserver = str_extract(observer, "\\d+")) %>% 
  select(-observer)

# group seis consist of multiple observers
# in this case, seis need to have the highest expertise observer score
# as the associated covariate

# get unique observers per sei
library(stringr)
dataSeiScore = distinct(dataCovar, sampling_event_identifier, observer_id) %>% 
  # make list column of observers
  mutate(observers = str_split(observer_id, ",")) %>% 
  unnest() %>% 
  # add numeric observer id
  mutate(numObserver = str_extract(observers, "\\d+")) %>% 
  # now get distinct sei and observer id numeric
  distinct(sampling_event_identifier, numObserver)

# now add expertise score to sei
dataSeiScore = left_join(dataSeiScore, expertiseScore) %>% 
  # get max expertise score per sei
  group_by(sampling_event_identifier) %>% 
  summarise(expertise = max(rptrScore))

# add to dataCovar
dataCovar = left_join(dataCovar, dataSeiScore, by = "sampling_event_identifier")

# remove data without expertise score
dataCovar = filter(dataCovar, !is.na(expertise))

# remove rasters
rm(alt, alt.hills, aspect, cr, EVI.all, EVI.yearly, EVI.all.resam, slope)
gc()

#### test for dataCovar class ####
# is dataCovar a dataframe?
# is dataCovar an sf? if so, manually drop geometry
assertthat::assert_that(!"sf" %in% class(dataCovar))

#### mean time, distance, and number of observers ####
# first count number of visits to each locality
localityCount = count(dataCovar, locality_id)

# summarise duration, distance, observers, and julian date as the sum
dataSummary = dataCovar %>%
  # first get julian date
  mutate(jul.date = lubridate::yday(as.Date(observation_date))) %>% 
  group_by(locality_id) %>% 
  summarise_at(vars(duration_minutes, effort_distance_km, number_observers, jul.date),
               list(sum.no.na))

# transform dataSummary to be a join of locality count and dataSummary
# then divide locality wise summarised sums by number of visits for the mean
dataSummary = left_join(dataSummary, localityCount, by = "locality_id") %>% 
  mutate_at(vars(duration_minutes, effort_distance_km, number_observers, jul.date),
            list(~(./n))) %>% 
  # rename variables to avoid confusion
  rename(mean_duration = duration_minutes, mean_distance = effort_distance_km, 
         mean_observers = number_observers, mean_date = jul.date) %>% 
  # remove n, which is the same as number of visits
  select(-n)

# join mean values to dataCovar
dataCovar = left_join(dataCovar, dataSummary, by = "locality_id")

# check again if dataCovar is a dataframe and not sf
assertthat::assert_that(is.data.frame(dataCovar))
assertthat::assert_that(!"sf" %in% class(dataCovar))

#### export to csv ####
write_csv(dataCovar, path = "data/dataCovars.csv")

# ends here
