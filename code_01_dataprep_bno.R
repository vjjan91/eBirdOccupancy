####prep data####

#### load data from raw files ####
#'load libs
library(tidyverse); library(readr); library(sf)
library(auk)

#'custom sum function
sum.no.na = function(x){sum(x, na.rm = T)}
#'custom drop geometry function
dropGeometry = function(x){
  x %>% bind_cols(data.frame(st_coordinates(.))) %>% `st_geometry<-`(NULL) %>% unclass() %>% as.data.frame()
}

#'set file paths for auk functions
f_in_ebd <- file.path("ebd_Filtered_May2018.txt")
f_in_sampling <- file.path("ebd_sampling_Filtered_May2018.txt")

#'run filters using auk packages
ebd_filters = auk_ebd(f_in_ebd, f_in_sampling) %>% 
  auk_species(c("Anthus nilghiriensis",
                "Montecincla cachinnans",
                "Montecincla fairbanki",
                "Sholicola albiventris",
                "Sholicola major",
                "Culicicapa ceylonensis",
                "Pomatorhinus horsfieldii",
                "Ficedula nigrorufa",
                "Pycnonotus jocosus",
                "Iole indica",
                "Hemipus picatus",
                "Saxicola caprata",
                "Eumyias albicaudatus",
                "Rhopocichla atriceps")) %>% 
  auk_country(country = "IN") %>%
  auk_state(c("IN-KL","IN-TN", "IN-KA")) %>% # Restricting geography to TamilNadu, Kerala & Karnataka
  auk_date(c("2000-01-01", "2018-09-17")) %>% 
  auk_complete()

#'check filters
ebd_filters

#'run filters and write
#'NB: this is already done, skip this step
#'

f_out_ebd <- "ebd_Filtered_May2018.txt"
f_out_sampling <- "ebd_sampling_Filtered_May2018.txt"

# Below code need not be run if it has been filtered once already and the above path leads to
# the right dataset 
# ebd_filtered <- auk_filter(ebd_filters, file = f_out_ebd, 
#                           file_sampling = f_out_sampling)

#### read the ebird data in ####
ebd <- read_ebd(f_out_ebd)
glimpse(ebd)

#### fill zeroes ####
zf <- auk_zerofill(f_out_ebd, f_out_sampling)
new_zf <- collapse_zerofill(zf) # Creates a new zero-filled dataframe with a 0 marked for each checklist when the bird was not observed
#   glimpse(zf)

#### remove old data ####
rm(data, ebd_filters, ebd_subset, zf, zf_subset)

#### subset data, choose black and orange flycatcher ####
columnsOfInterest = c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed")

speciesOfInterest = c("Ficedula nigrorufa")

data = list(ebd, new_zf) %>% 
  map(function(x){
    x %>% select(one_of(columnsOfInterest)) %>% 
      filter(scientific_name %in% speciesOfInterest)
    # %>% dlply("scientific_name")
    #'this above for when there are more species
  })

#### filter spatially ####
#'load shapefiles of hill ranges
library(sf)
hills = st_read("hillsShapefile/Nil_Ana_Pal.shp")
#'convert data to sf and filter spatially
data = data %>% 
  map(function(x){
    x %>% st_as_sf(coords = c("longitude","latitude")) %>% 
      st_set_crs(4326)
  }) %>% 
  map(function(x){
    st_intersection(hills, x)
  })

#### presence and absence ####
#'save a temp data file
#save(data, file = "data.temp.rdata")

load("data.temp.rdata")
  
#'check presence and absence in absences df, remove essentially the presences df
data[[2]] = data[[2]] %>% filter(species_observed == F)

#'in the first set, replace X, for presences, with 1
data[[1]] = data[[1]] %>% mutate(observation_count = ifelse(observation_count == "X", "1", observation_count))

#'remove records where duration is 0 and effort was > 0
data = map(data, function(x) filter(x, duration_minutes > 0))

#### custom functions ####

library(sf)
#'remove spatial geometry, preserve coordinates
data = map(data, function(x){
  x %>% bind_cols(data.frame(st_coordinates(.))) %>% `st_geometry<-`(NULL) %>% unclass() %>% as.data.frame()
})

#'group data by site and sampling event identifier
#'then, sum relevant variables
#'then, join by SEI to df of largely constant vars, such as locality
dataGrouped = map(data, function(x){
    x %>% group_by(sampling_event_identifier) %>% 
      summarise_at(vars(duration_minutes, effort_distance_km, effort_area_ha), funs(sum.no.na))
  }) %>% 
  map2(data %>% 
         map(function(x){select(x, sampling_event_identifier, time_observations_started, locality, locality_type, locality_id, observer_id, observation_date, scientific_name, observation_count, protocol_type, number_observers, X, Y)}), left_join)

#'bind rows combining data frames, and filter
dataGrouped = bind_rows(dataGrouped) %>% 
  filter(duration_minutes <= 240, effort_distance_km <= 5, effort_area_ha <= 500)

#'assign present or not
dataGrouped = mutate(dataGrouped, pres_abs = observation_count >= 1)
  
#### load covariates from raster files ####
#'load elevation and crop to hills size, then mask by hills
#' sf
alt = raster::raster("Elevation/alt/")
cr = raster::crop(alt, raster::extent(as(hills, "Spatial")))
alt.hills = raster::mask(cr, as(hills, "Spatial"))

#'load evi layers
EVI.all = raster::stack("EVI/MOD13Q1_EVI_AllYears.tif")
x11();raster::plot(EVI.all)
#'scale later
#'EVI.all = EVI.all*0.0001
names(EVI.all) = paste("evi", month.abb, sep = ".")

#'load 5 year evi change(?) this is currently 6 years
evifiles = list.files("EVI", pattern = "_201", full.names = T)
evifiles = evifiles[as.numeric(stringi::stri_sub(evifiles, -8, -5)) >= 2013]

#'make stack
EVI.yearly = raster::stack(as.list(evifiles))
#'scale stack later
#EVI.yearly = EVI.yearly*0.0001

#'resample to elevation resolution
EVI.all.resam <-  raster::resample(EVI.all, alt.hills,method ="bilinear")
EVI.yearly.resam <- raster::resample(EVI.yearly, alt.hills, method="bilinear")

#'get slope and aspect
slope <- raster::terrain(alt.hills, opt = 'slope', unit='degrees', neighbors = 8)
aspect <- raster::terrain(alt.hills, opt='aspect', unit='degrees', neighbors = 8)


#### extracting raster values #####
#'make raster list
landscapeRasters = list(alt.hills, EVI.all.resam, slope, aspect)

#'make dataGrouped sf again
dataGrouped = st_as_sf(dataGrouped, coords = c("X", "Y")) %>% st_set_crs(4326)

#'map extract across the list
landscapeData = map(landscapeRasters, function(x){
  raster::extract(x, dataGrouped)
})
#'set names
names(landscapeData) = c("elevation","evi","slope","aspect")

#'bind into dataframe
landscapeData = map(landscapeData, as_data_frame) %>% bind_cols() %>% 
  `names<-`(c("elevation", paste("evi", month.abb, sep = "."), "slope", "aspect"))

#'join with ebird data
dataCovar = bind_cols(dataGrouped, landscapeData)

#'remove rasters
rm(alt, alt.hills, aspect, cr, EVI.all, EVI.yearly, EVI.yearly.resam, EVI.all.resam, slope)
gc()

#### mean time, distance, and number of observers ####

dataCovar = dropGeometry(dataCovar)

dataCovar = dataCovar %>% 
  left_join(dataCovar %>% 
      group_by(locality_id) %>% 
      summarise_at(vars(duration_minutes, effort_distance_km, number_observers),
                   funs(sum.no.na)) %>% 
      left_join(count(dataCovar, locality_id)) %>% 
      mutate_at(vars(duration_minutes, effort_distance_km, number_observers),
                funs(./n)) %>% 
        `names<-`(c("locality_id", "meanSampleTime", "meanSampleDist", "meanNObservers", "totalVisits"))
  )
