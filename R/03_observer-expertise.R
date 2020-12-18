## ----load_libs3, eval=FALSE, message=FALSE, warning=FALSE---------------------
## 
## # load libs
## library(data.table)
## library(readxl)
## library(magrittr)
## library(stringr)
## library(dplyr)
## library(tidyr)
## library(auk)
## 
## # get decimal time function
## library(lubridate)
## time_to_decimal <- function(x) {
##   x <- lubridate::hms(x, quiet = TRUE)
##   lubridate::hour(x) + lubridate::minute(x) / 60 + lubridate::second(x) / 3600
## }


## ----load_raw_data, eval=FALSE------------------------------------------------
## # Read in shapefile of study area to subset by bounding box
## library(sf)
## wg <- st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp") %>%
##   st_transform(32643)
## 
## # set file paths for auk functions
## f_in_ebd <- file.path("data/eBirdDataWG_filtered.txt")
## f_in_sampling <- file.path("data/eBirdSamplingDataWG_filtered.txt")
## 
## # run filters using auk packages
## ebd_filters <- auk_ebd(f_in_ebd, f_in_sampling) %>%
##   auk_country(country = "IN") %>%
##   auk_state(c("IN-KL", "IN-TN", "IN-KA")) %>%
##   # Restricting geography to TamilNadu, Kerala & Karnataka
##   auk_date(c("2013-01-01", "2019-12-31")) %>%
##   auk_complete()
## 
## # check filters
## ebd_filters
## 
## # specify output location and perform filter
## f_out_ebd <- "data/ebird_for_expertise.txt"
## f_out_sampling <- "data/ebird_sampling_for_expertise.txt"
## 
## ebd_filtered <- auk_filter(ebd_filters,
##   file = f_out_ebd,
##   file_sampling = f_out_sampling, overwrite = TRUE
## )


## ----read_all_ebd, eval=FALSE-------------------------------------------------
## ## Process filtered data
## # read in the data
## ebd <- fread(f_out_ebd)
## names <- names(ebd) %>%
##   stringr::str_to_lower() %>%
##   stringr::str_replace_all(" ", "_")
## 
## setnames(ebd, names)
## # choose columns of interest
## columnsOfInterest <- c(
##   "checklist_id", "scientific_name", "observation_count",
##   "locality", "locality_id", "locality_type", "latitude",
##   "longitude", "observation_date",
##   "time_observations_started", "observer_id",
##   "sampling_event_identifier", "protocol_type",
##   "duration_minutes", "effort_distance_km", "effort_area_ha",
##   "number_observers", "species_observed", "reviewed"
## )
## 
## ebd <- setDF(ebd) %>%
##   as_tibble() %>%
##   dplyr::select(one_of(columnsOfInterest))
## 
## setDT(ebd)


## ----hills_subset_exp, eval=FALSE---------------------------------------------
## # get checklist locations
## ebd_locs <- ebd[, .(longitude, latitude)]
## ebd_locs <- setDF(ebd_locs) %>% distinct()
## ebd_locs <- st_as_sf(ebd_locs,
##   coords = c("longitude", "latitude")
## ) %>%
##   `st_crs<-`(4326) %>%
##   bind_cols(as_tibble(st_coordinates(.))) %>%
##   st_transform(32643) %>%
##   mutate(id = 1:nrow(.))
## 
## # check whether to include
## to_keep <- unlist(st_contains(wg, ebd_locs))
## 
## # filter locs
## ebd_locs <- filter(ebd_locs, id %in% to_keep) %>%
##   bind_cols(as_tibble(st_coordinates(st_as_sf(.)))) %>%
##   st_drop_geometry()


## ----hills_subset_exp2, eval=FALSE--------------------------------------------
## ebd <- ebd[longitude %in% ebd_locs$X & latitude %in% ebd_locs$Y, ]


## ----soi_score, eval=FALSE----------------------------------------------------
## # read in species list
## specieslist <- read.csv("data/species_list.csv")
## 
## # set species of interest
## soi <- specieslist$scientific_name
## 
## ebdSpSum <- ebd[, .(
##   nSp = .N,
##   totSoiSeen = length(intersect(scientific_name, soi))
## ),
## by = list(sampling_event_identifier)
## ]
## 
## # write to file and link with checklsit id later
## fwrite(ebdSpSum, file = "data/dataChecklistSpecies.csv")


## ----prepare_chk_covars, eval=FALSE-------------------------------------------
## # 1. add new columns of decimal time and julian date
## ebd[, `:=`(
##   decimalTime = time_to_decimal(time_observations_started),
##   julianDate = yday(as.POSIXct(observation_date))
## )]
## 
## ebdEffChk <- setDF(ebd) %>%
##   mutate(year = year(observation_date)) %>%
##   distinct(
##     sampling_event_identifier, observer_id,
##     year,
##     duration_minutes, effort_distance_km, effort_area_ha,
##     longitude, latitude,
##     locality, locality_id,
##     decimalTime, julianDate, number_observers
##   ) %>%
##   # drop rows with NAs in cols used in the model
##   tidyr::drop_na(
##     sampling_event_identifier, observer_id,
##     duration_minutes, decimalTime, julianDate
##   ) %>%
## 
##   # drop years below 2013
##   filter(year >= 2013)
## 
## # 3. join to covariates and remove large groups (> 10)
## ebdChkSummary <- inner_join(ebdEffChk, ebdSpSum)
## 
## # remove ebird data
## rm(ebd)
## gc()


## ----chk_covar_landuse, eval=FALSE--------------------------------------------
## # read in 1km landcover and set 0 to NA
## library(raster)
## landcover <- raster::raster("data/landUseClassification/lc_01000m.tif")
## landcover[landcover == 0] <- NA
## 
## # get locs in utm coords
## locs <- distinct(
##   ebdChkSummary, sampling_event_identifier, longitude, latitude,
##   locality, locality_id
## )
## locs <- st_as_sf(locs, coords = c("longitude", "latitude")) %>%
##   `st_crs<-`(4326) %>%
##   st_transform(32643) %>%
##   st_coordinates()
## 
## # get for unique points
## landcoverVec <- raster::extract(
##   x = landcover,
##   y = locs
## )
## 
## # assign to df and overwrite
## setDT(ebdChkSummary)[, landcover := landcoverVec]


## ----filter_data2, eval=FALSE-------------------------------------------------
## # change names for easy handling
## setnames(ebdChkSummary, c(
##   "sei", "observer", "year", "duration", "distance",
##   "area", "longitude", "latitude", "locality",
##   "locality_id", "decimalTime",
##   "julianDate", "nObs", "nSp", "nSoi", "landcover"
## ))
## 
## # count data points per observer
## obscount <- count(ebdChkSummary, observer) %>%
##   filter(n >= 10)
## 
## # make factor variables and remove obs not in obscount
## # also remove 0 durations
## ebdChkSummary <- ebdChkSummary %>%
##   mutate(
##     distance = ifelse(is.na(distance), 0, distance),
##     duration = if_else(is.na(duration), 0.0, as.double(duration))
##   ) %>%
##   filter(
##     observer %in% obscount$observer,
##     duration > 0,
##     duration <= 300,
##     nSoi >= 0,
##     distance <= 5,
##     !is.na(nSoi)
##   ) %>%
##   mutate(
##     landcover = as.factor(landcover),
##     observer = as.factor(observer)
##   ) %>%
##   drop_na(landcover)
## 
## 
## # save to file for later reuse
## fwrite(ebdChkSummary, file = "data/eBirdChecklistVars.csv")


## ----run_model, eval=FALSE----------------------------------------------------
## # uses either a subset or all data
## library(lmerTest)
## 
## # here we specify a glmm with random effects for observer
## # time is considered a fixed log predictor and a random slope
## modObsExp <- glmer(nSoi ~ sqrt(duration) +
##   landcover +
##   sqrt(decimalTime) +
##   I((sqrt(decimalTime))^2) +
##   log(julianDate) +
##   I((log(julianDate)^2)) +
##   (1 | observer) + (0 + duration | observer),
## data = ebdChkSummary, family = "poisson"
## )


## ----write_obsexp_model, eval=FALSE-------------------------------------------
## # make dir if absent
## if (!dir.exists("data/modOutput")) {
##   dir.create("data/modOutput")
## }
## 
## # write model output to text file
## {
##   writeLines(R.utils::captureOutput(list(Sys.time(), summary(modObsExp))),
##     con = "data/modOutput/modOutExpertise.txt"
##   )
## }


## ----obsexp_ranef, eval=FALSE-------------------------------------------------
## # make df with means
## observer <- unique(ebdChkSummary$observer)
## 
## # predict at 60 mins on the most common landcover
## dfPredict <- ebdChkSummary %>%
##   summarise_at(vars(duration, decimalTime, julianDate), list(~ mean(.))) %>%
##   mutate(duration = 60, landcover = as.factor(6)) %>%
##   tidyr::crossing(observer)
## 
## # run predict from model on it
## dfPredict <- mutate(dfPredict,
##   score = predict(modObsExp,
##     newdata = dfPredict,
##     type = "response",
##     allow.new.levels = TRUE
##   )
## ) %>%
##   mutate(score = scales::rescale(score))


## ----write_obsexp, eval=FALSE-------------------------------------------------
## fwrite(dfPredict %>% dplyr::select(observer, score),
##   file = "data/dataObsExpScore.csv"
## )

