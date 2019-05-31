# load libs
library(dplyr); library(data.table)
library(stringr)

# read in shapefile of wg to subset by bounding box
library(sf)
wg <- st_read("hillsShapefile/Nil_Ana_Pal.shp")
box <- st_bbox(wg)

# read in data with fread
ebd = fread("ebd_Filtered_May2018.txt")

#### write subset to file ####
ebdHills <- ebd[between(LONGITUDE, box["xmin"], box["xmax"]) & between(LATITUDE, box["ymin"], box["ymax"]),]

# get names and set to lower case
names <- str_to_lower(names(ebdHills))
setnames(ebdHills, names(ebdHills), names)
fwrite(ebdHills, file = "data/eBirdDataWG.csv")

# write sampling information to file
# read in top rows of sampling names
samplingData <- fread("ebd_sampling_Filtered_May2018.txt", nrows = 5)
samplingCols <- names(samplingData) %>% str_to_lower()
# get sampling cols
ebdHillSamplingData <- select(ebdHills, one_of(samplingCols)) %>% distinct()

# write csv
fwrite(ebdHillSamplingData, file = "data/eBirdSamplingDataWG.csv")
