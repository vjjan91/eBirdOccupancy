#### code to prepare data for expertise score modelling ####

# to note: habitat type raster is only covers western ghats
# code has been modified to model expertise only from within the WG shapefile BOUNDS

# to be run as a script
rm(list = ls()); gc()

# load libs
library(data.table)
library(readxl)
#### load data and subset ####

# read in shapefile of nilgiris to subset by bounding box
library(sf)
wg <- st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp"); box <- st_bbox(wg)

# read in data and subset
ebd = fread("ebd_Filtered_Jun2019.txt")[between(LONGITUDE, box["xmin"], box["xmax"]) & between(LATITUDE, box["ymin"], box["ymax"]),][year(`OBSERVATION DATE`) >= 2013,]

# make new column names
library(magrittr); library(stringr)
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
setnames(ebd, newNames)

# keep useful columns
columnsOfInterest <- c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- dplyr::select(ebd, dplyr::one_of(columnsOfInterest))

# # read in data
# ebd <- fread("data/dataForUse.csv")

gc()

# get the checklist id as SEI or group id
ebd[,checklist_id := ifelse(group_identifier == "", 
                            sampling_event_identifier, group_identifier),]

# n checklists per observer
ebdNchk <- ebd[,year:=year(observation_date)
               ][,.(nChk = length(unique(checklist_id)), 
                  nSei = length(unique(sampling_event_identifier))), 
               by= list(observer_id, year)]

# get decimal time function
library(lubridate)
time_to_decimal <- function(x) {
  x <- hms(x, quiet = TRUE)
  hour(x) + minute(x) / 60 + second(x) / 3600
}

#### count species per SEI per observer ####
# this is necessary since checklists can have more than one
# sampling events with overlapping species
# to solve this, especially in group checklists, simply run the analysis
# at the SEI level

# count the number of records of SEI and observer combinations
# count number of species of the focal species seen per sei per observer
# get species of interest list
# add species of interest
specieslist = read_excel(path = "data/species_list_13_11_2019.xlsx")

# set species of interest
soi = specieslist$scientific_name

ebdSpSum <- ebd[,.(nSp = .N,
                   totSoiSeen = length(intersect(scientific_name, soi))), 
                by = list(sampling_event_identifier, observer_id, year)]

# write to file and link with checklsit id later
fwrite(ebdSpSum, file = "data/dataChecklistSpecies.csv")

# 1. add new columns of decimal time and julian date
ebd[,`:=`(decimalTime = time_to_decimal(time_observations_started),
          julianDate = yday(as.POSIXct(observation_date)))]

# write useful data to file
fwrite(ebd, "data/dataForUse.csv")

# 2. get the summed effort and distance for each checklist
# and the first of all other variables
library(dplyr)
ebdEffChk <- setDF(ebd) %>% 
  mutate(year = year(observation_date)) %>% 
  distinct(sampling_event_identifier, observer_id,
           year,
           duration_minutes, effort_distance_km, longitude, latitude,
           decimalTime, julianDate, number_observers) %>% 
  # drop rows with NAs in cols used in the model
  tidyr::drop_na(sampling_event_identifier, observer_id,
          duration_minutes, decimalTime, julianDate) %>% 
  
  # drop years below 2013
  filter(year >= 2013)

# 3. join to covariates and remove large groups (> 10)
ebdChkSummary <- inner_join(ebdEffChk, ebdSpSum)#

# count groups larger than 10
count(ebdEffChk, number_observers > 10)

# remove only groups greater than 10 obs
ebdChkSummary <- ebdChkSummary %>% 
  filter(number_observers <= 10, !is.na(number_observers))

# remove ebird data
rm(ebd); gc()

#### get landcover ####
# here, we read in the landcover raster and assign a landcover value
# to each checklist. checklists might consist of one or more landcovers
# in some cases, but we assign only one based on the first coord pair
# read in raster
landcover <- raster::raster("data/landUseClassification/Classified Image_31stAug_WGS84_Ghats.tif")

# get for unique points
landcoverVec <- raster::extract(x = landcover, y = as.matrix(ebdChkSummary[,c("longitude","latitude")]))

# assign to df and overwrite
setDT(ebdChkSummary)[,landcover:= landcoverVec]

fwrite(ebdChkSummary, file = "data/eBirdChecklistVars.csv")

# end here
