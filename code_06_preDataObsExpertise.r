#### code to prepare data for expertise score modelling ####

# to note: habitat type raster is only covers western ghats
# code has been modified to model expertise only from within the WG shapefile BOUNDS

# to be run as a script
rm(list = ls()); gc()

# load libs
library(data.table)
library(stringr)

# read in shapefile of wg to subset by bounding box
library(sf)
wg <- st_read("hillsShapefile/WG.shp")
box <- st_bbox(wg)

# read in data with fread
ebd = fread("ebd_Filtered_May2018.txt")

#### write subset to file ####
ebd <- ebd[between(LONGITUDE, box["xmin"], box["xmax"]) & between(LATITUDE, box["ymin"], box["ymax"]),]

# make new column names
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
setnames(ebd, newNames)

# keep useful columns
columnsOfInterest <- c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- dplyr::select(ebd, dplyr::one_of(columnsOfInterest))

gc()

# get the checklist id as SEI or group id
ebd[,checklist_id := ifelse(group_identifier == "", sampling_event_identifier, group_identifier),]

# n checklists per observer
ebdNchk <- ebd[,year:=year(observation_date)][,.(nChk = length(unique(checklist_id)), 
                  nSei = length(unique(sampling_event_identifier))), 
               by= list(observer_id, year)]

# get decimal time function
library(lubridate)
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}

# get species per checklist and SEI (each SEI is a different location)
ebdNspChk <- ebd[, .(samplingEffort = max(duration_minutes),
                     samplingDistance = max(effort_distance_km),
                     decimalTime = first(time_to_decimal(time_observations_started)),
                     julianDate = first(yday(as.POSIXct(observation_date))),
                     latitude = first(latitude),
                     longitude = first(longitude),
                     observer = first(observer_id),
                     .N),
                 by = list(checklist_id, sampling_event_identifier)]

# remove ebird data
rm(ebd); gc()

# write data to file
fwrite(ebdNspChk, file = "data/eBirdChecklistSpecies.csv")
fwrite(ebdNchk, file = "data/eBirdNchecklistObserver.csv")

#### hbaitat type as landcover ####
# read in raster
landcover <- raster::raster("data/glob_cover_wghats.tif")

# get for unique points
landcoverVec <- raster::extract(x = landcover, y = as.matrix(ebdNspChk[,c("longitude","latitude")]))

# assign to df and overwrite
ebdNspChk[,landcover:= landcoverVec]
fwrite(ebdNspChk, file = "data/eBirdChecklistSpecies.csv")