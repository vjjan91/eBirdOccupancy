#### code to prepare data for expertise score modelling ####

# to be run as a script
rm(list = ls()); gc()

# load libs
library(data.table)
library(stringr)

# read in data with fread
ebd = fread("ebd_Filtered_May2018.txt")

# make new column names
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
setnames(ebd, newNames)

# keep useful columns
columnsOfInterest = c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- dplyr::select(ebd, dplyr::one_of(columnsOfInterest))

gc()

# get the checklist id as SEI or group id
ebd[,checklist_id := ifelse(group_identifier == "", sampling_event_identifier, group_identifier),]

# n checklists per observer
ebdNchk <- ebd[,.(nChk = length(unique(checklist_id)), 
                  nSei = length(unique(sampling_event_identifier))), 
               by= list(observer_id)]

# get decimal time function
library(lubridate)
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}

# get species per checklist and SEI (each SEI is a different location)
ebdNspChk <- ebd[, .(samplingEffort = max(duration_minutes),
                     # samplingDistance = max(effort_distance_km),
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
# # suspended for now since landcover raster is not the same size as expertise score data
# # read in raster
# landcover <- raster::raster("Classified Image_3rdJune2019_WG.tif")
# 
# # get for unique points
# landcoverVec <- raster::extract(x = landcover, y = as.matrix(ebd[,c("longitude","latitude")]))

