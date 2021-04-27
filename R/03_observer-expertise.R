#' ---
#' editor_options: 
#'   chunk_output_type: console
#' ---
#' 
#' # Preparing Observer Expertise Scores
#' 
#' Differences in local avifaunal expertise among citizen scientists can lead to biased species detection when compared with data collected by a consistent set of trained observers [@vanstrien2013]. Including observer expertise as a detection covariate in occupancy models using eBird data can help account for this variation [@johnston2018]. Observer-specific expertise in local avifauna was calculated following [@kelling2015a] as the normalized predicted number of species reported by an observer after 60 minutes of sampling across the most common land cover type within the study area. This score was calculated by examining checklists from anonymized observers across the study area. We modified Kelling et al. (2015) formulation by including only observations of the 93 species of interest in our calculations. An observer with a higher number of species of interest reported within 60 minutes would have a higher observer-specific expertise score, with respect to the study area. 
#' 
#' Plots with respect to how observer expertise varied over time (2013-2019) for the list of species considered in this study (across the study area alone) can be accessed in Section 7 of the Supplementary Material. 
#' 
#' ## Prepare libraries
#' 
## ----load_libs3, , message=FALSE, warning=FALSE-------------------------------

# load libs
library(data.table)
library(readxl)
library(magrittr)
library(stringr)
library(dplyr)
library(tidyr)
library(auk)

# get decimal time function
library(lubridate)
time_to_decimal <- function(x) {
  x <- lubridate::hms(x, quiet = TRUE)
  lubridate::hour(x) + lubridate::minute(x) / 60 + lubridate::second(x) / 3600
}

#' 
#' ## Prepare data
#' 
#' Here, we go through the data preparation process again because we might want to assess observer expertise over a larger area than the study site.
## ----load_raw_data------------------------------------------------------------
# Read in shapefile of study area to subset by bounding box
library(sf)
wg <- st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp") %>%
  st_transform(32643)

# set file paths for auk functions
f_in_ebd <- file.path("data/01_ebird-filtered-EBD-westernGhats.txt")
f_in_sampling <- file.path("data/01_ebird-filtered-sampling-westernGhats.txt")

# run filters using auk packages
ebd_filters <- auk_ebd(f_in_ebd, f_in_sampling) %>%
  auk_country(country = "IN") %>%
  auk_state(c("IN-KL", "IN-TN", "IN-KA")) %>%
  # Restricting geography to TamilNadu, Kerala & Karnataka
  auk_date(c("2013-01-01", "2019-12-31")) %>%
  auk_complete()

# check filters
ebd_filters

# specify output location and perform filter
f_out_ebd <- "data/ebird_for_expertise.txt"
f_out_sampling <- "data/ebird_sampling_for_expertise.txt"

ebd_filtered <- auk_filter(ebd_filters,
  file = f_out_ebd,
  file_sampling = f_out_sampling, overwrite = TRUE
)

#' 
#' Load in the filtered data and columns of interest. 
## ----read_all_ebd-------------------------------------------------------------
## Process filtered data
# read in the data
ebd <- fread(f_out_ebd)
names <- names(ebd) %>%
  stringr::str_to_lower() %>%
  stringr::str_replace_all(" ", "_")

setnames(ebd, names)
# choose columns of interest
columnsOfInterest <- c(
  "checklist_id", "scientific_name", "observation_count",
  "locality", "locality_id", "locality_type", "latitude",
  "longitude", "observation_date",
  "time_observations_started", "observer_id",
  "sampling_event_identifier", "protocol_type",
  "duration_minutes", "effort_distance_km", "effort_area_ha",
  "number_observers", "species_observed", "reviewed"
)

ebd <- setDF(ebd) %>%
  as_tibble() %>%
  dplyr::select(one_of(columnsOfInterest))

setDT(ebd)

#' 
#' ## Spatially explicit filter on checklists
#' 
## ----hills_subset_exp---------------------------------------------------------
# get checklist locations
ebd_locs <- ebd[, .(longitude, latitude)]
ebd_locs <- setDF(ebd_locs) %>% distinct()
ebd_locs <- st_as_sf(ebd_locs,
  coords = c("longitude", "latitude")
) %>%
  `st_crs<-`(4326) %>%
  bind_cols(as_tibble(st_coordinates(.))) %>%
  st_transform(32643) %>%
  mutate(id = 1:nrow(.))

# check whether to include
to_keep <- unlist(st_contains(wg, ebd_locs))

# filter locs
ebd_locs <- filter(ebd_locs, id %in% to_keep) %>%
  bind_cols(as_tibble(st_coordinates(st_as_sf(.)))) %>%
  st_drop_geometry()

#' 
## ----hills_subset_exp2--------------------------------------------------------
ebd <- ebd[longitude %in% ebd_locs$X & latitude %in% ebd_locs$Y, ]

#' 
#' ## Prepare species of interest
#' 
## ----soi_score----------------------------------------------------------------
# read in species list
specieslist <- read.csv("data/species_list.csv")

# set species of interest
soi <- specieslist$scientific_name

ebdSpSum <- ebd[, .(
  nSp = .N,
  totSoiSeen = length(intersect(scientific_name, soi))
),
by = list(sampling_event_identifier)
]

# write to file and link with checklist id later
fwrite(ebdSpSum, file = "data/03_data-nspp-per-chk.csv")

#' 
#' ## Prepare checklists for observer score
#' 
## ----prepare_chk_covars-------------------------------------------------------
# 1. add new columns of decimal time and julian date
ebd[, `:=`(
  decimalTime = time_to_decimal(time_observations_started),
  julianDate = yday(as.POSIXct(observation_date))
)]

ebdEffChk <- setDF(ebd) %>%
  mutate(year = year(observation_date)) %>%
  distinct(
    sampling_event_identifier, observer_id,
    year,
    duration_minutes, effort_distance_km, effort_area_ha,
    longitude, latitude,
    locality, locality_id,
    decimalTime, julianDate, number_observers
  ) %>%
  # drop rows with NAs in cols used in the model
  tidyr::drop_na(
    sampling_event_identifier, observer_id,
    duration_minutes, decimalTime, julianDate
  ) %>%

  # drop years below 2013
  filter(year >= 2013)

# 3. join to covariates and remove large groups (> 10)
ebdChkSummary <- inner_join(ebdEffChk, ebdSpSum)

# remove ebird data
rm(ebd)
gc()

#' 
#' ## Get landcover
#' 
#' Read in land cover type data resampled at 1km resolution.
## ----chk_covar_landuse--------------------------------------------------------
# read in 1km landcover and set 0 to NA
library(raster)
landcover <- raster::raster("data/landUseClassification/lc_01000m.tif")
landcover[landcover == 0] <- NA

# get locs in utm coords
locs <- distinct(
  ebdChkSummary, sampling_event_identifier, longitude, latitude,
  locality, locality_id
)
locs <- st_as_sf(locs, coords = c("longitude", "latitude")) %>%
  `st_crs<-`(4326) %>%
  st_transform(32643) %>%
  st_coordinates()

# get for unique points
landcoverVec <- raster::extract(
  x = landcover,
  y = locs
)

# assign to df and overwrite
setDT(ebdChkSummary)[, landcover := landcoverVec]

#' 
#' ## Filter checklist data
#' 
## ----filter_data2-------------------------------------------------------------
# change names for easy handling
setnames(ebdChkSummary, c(
  "sei", "observer", "year", "duration", "distance",
  "area", "longitude", "latitude", "locality",
  "locality_id", "decimalTime",
  "julianDate", "nObs", "nSp", "nSoi", "landcover"
))

# count data points per observer
obscount <- count(ebdChkSummary, observer) %>%
  filter(n >= 10)

# make factor variables and remove obs not in obscount
# also remove 0 durations
ebdChkSummary <- ebdChkSummary %>%
  mutate(
    distance = ifelse(is.na(distance), 0, distance),
    duration = if_else(is.na(duration), 0.0, as.double(duration))
  ) %>%
  filter(
    observer %in% obscount$observer,
    duration > 0,
    duration <= 300,
    nSoi >= 0,
    distance <= 5,
    !is.na(nSoi)
  ) %>%
  mutate(
    landcover = as.factor(landcover),
    observer = as.factor(observer)
  ) %>%
  drop_na(landcover)


# save to file for later reuse
fwrite(ebdChkSummary, file = "data/03_data-covars-perChklist.csv")

#' 
#' ## Model observer expertise
#' 
#' Our observer expertise model aims to include the random intercept effect of observer identity, with a random slope effect of duration. This models the different rate of species accumulation by different observers, as well as their different starting points.
## ----run_model----------------------------------------------------------------
# uses either a subset or all data
library(lmerTest)

# here we specify a glmm with random effects for observer
# time is considered a fixed log predictor and a random slope
modObsExp <- glmer(nSoi ~ sqrt(duration) +
  landcover +
  sqrt(decimalTime) +
  I((sqrt(decimalTime))^2) +
  log(julianDate) +
  I((log(julianDate)^2)) +
  (1 | observer) + (0 + duration | observer),
data = ebdChkSummary, family = "poisson"
)

#' 
## ----write_obsexp_model-------------------------------------------------------
# make dir if absent
if (!dir.exists("data/modOutput")) {
  dir.create("data/modOutput")
}

# write model output to text file
{
  writeLines(R.utils::captureOutput(list(Sys.time(), summary(modObsExp))),
    con = "data/modOutput/03_model-output-expertise.txt"
  )
}

#' 
## ----obsexp_ranef-------------------------------------------------------------
# make df with means
observer <- unique(ebdChkSummary$observer)

# predict at 60 mins on the most common landcover
dfPredict <- ebdChkSummary %>%
  summarise_at(vars(duration, decimalTime, julianDate), list(~ mean(.))) %>%
  mutate(duration = 60, landcover = as.factor(6)) %>%
  tidyr::crossing(observer)

# run predict from model on it
dfPredict <- mutate(dfPredict,
  score = predict(modObsExp,
    newdata = dfPredict,
    type = "response",
    allow.new.levels = TRUE
  )
) %>%
  mutate(score = scales::rescale(score))

#' 
## ----write_obsexp-------------------------------------------------------------
fwrite(dfPredict %>% dplyr::select(observer, score),
  file = "data/03_data-obsExpertise-score.csv"
)

