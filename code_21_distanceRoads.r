#### code for checklist dist to roads distr ####

# load libs
library(data.table)
library(sf)

# load data and subset
roads <- st_read("data/spatial/roads_studysite_2019/")
hills <- st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp")

# read in data and get spatial coords
data <- fread("data/eBirdChecklistVars.csv")

library(dplyr)
pts <- distinct(setDF(data), longitude, latitude)
pts <- st_as_sf(pts, coords = c("longitude", "latitude"))
st_crs(pts) <- st_crs(hills)

# clip by hills
pts_hills <- st_join(pts, hills, join=st_intersects) %>% 
  filter(!is.na(Id))

# get distance to roads
st_distance(pts_hills, roads[1:10,],)
