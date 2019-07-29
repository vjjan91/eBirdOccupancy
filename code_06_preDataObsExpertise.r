#### code to prepare data for expertise score modelling ####

# to note: habitat type raster is only covers western ghats
# code has been modified to model expertise only from within the WG shapefile BOUNDS

# to be run as a script
rm(list = ls()); gc()

# load libs
library(data.table)

# read in shapefile of wg to subset by bounding box
library(sf)
wg <- st_read("hillsShapefile/WG.shp"); box <- st_bbox(wg)

# read in data and subset
ebd = fread("ebd_Filtered_May2018.txt")[between(LONGITUDE, box["xmin"], box["xmax"]) & between(LATITUDE, box["ymin"], box["ymax"]),]

# make new column names
library(magrittr); library(stringr)
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
setnames(ebd, newNames)

# keep useful columns
columnsOfInterest <- c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- dplyr::select(ebd, dplyr::one_of(columnsOfInterest))

gc()

# get the checklist id as SEI or group id
ebd[,checklist_id := ifelse(group_identifier == "", 
                            sampling_event_identifier, group_identifier),]

# n checklists per observer
ebdNchk <- ebd[,year:=year(observation_date)
               ][,.(nChk = length(unique(checklist_id)), 
                  nSei = length(unique(sampling_event_identifier))), 
               by= list(observer_id, year)]

# print as confirmation that SEIs are checklists
{pdf(file = "figs/figNchkVsNsei.pdf")
  plot(ebdNchk$nChk, ebdNchk$nSei); abline(a = 0, b=1)
  dev.off()
}

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
ebdSpSum <- ebd[,.N, by = list(sampling_event_identifier, observer_id)]

# write to file and link with checklsit id later
fwrite(ebdSpSum, file = "data/dataChecklistSpecies.csv")

# 1. add new columns of decimal time and julian date
ebd[,`:=`(decimalTime = time_to_decimal(time_observations_started),
          julianDate = yday(as.POSIXct(observation_date)))]

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
          duration_minutes, decimalTime, julianDate)

# count groups larger than 10
count(ebdEffChk, number_observers > 10)

# 3. join to covariates and remove large groups (> 10)
ebdChkSummary <- inner_join(ebdEffChk, ebdSpSum)#

# plot relationship between species and observers
tempdata <- setDT(ebdChkSummary)[,roundobs:=plyr::round_any(number_observers, 5)
                                 ][,.(mean = mean(N),
                                    sd = sd(N)), by = roundobs]

# plot and check
ggplot(tempdata)+
  geom_pointrange(aes(x = roundobs, y = mean, ymin=mean-sd, ymax=mean+sd),
                  col = "grey40")+
  xlim(0, 200)+
  geom_hline(yintercept = 30, col = 2)+
  theme_light()+labs(x = "osbervers", y = "species seen")

ggsave(filename = "figs/figNspVsObs.pdf", height = 6, width = 6, device = "pdf")

# remove only groups greater than 50 obs
ebdChkSummary <- ebdChkSummary %>% 
  filter(number_observers <= 50, !is.na(number_observers))

# remove ebird data
rm(ebd); gc()

# write number of checklists per observer to file
fwrite(ebdNchk, file = "data/eBirdNchecklistObserver.csv")

#### get landcover ####
# here, we read in the landcover raster and assign a landcover value
# to each checklist. checklists might consist of one or more landcovers
# in some cases, but we assign only one based on the first coord pair
# read in raster
landcover <- raster::raster("data/glob_cover_wghats.tif")

# get for unique points
landcoverVec <- raster::extract(x = landcover, y = as.matrix(ebdChkSummary[,c("longitude","latitude")]))

# assign to df and overwrite
setDT(ebdChkSummary)[,landcover:= landcoverVec]

fwrite(ebdChkSummary, file = "data/eBirdChecklistVars.csv")

# end here