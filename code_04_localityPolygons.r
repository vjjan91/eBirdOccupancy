#### identifying localities ####
#'in this code, collect unique combinations of coordinates and locality
#'then draw a 95% kde around them
#'plot in tmap/other
#'
#### load libs and data ####
#'libs
library(tidyverse); library(readr); library(sf)

#'load data
data = read_csv("data/dataCovars.csv")
#'isolate unique coord - locality triads
dataLocs = data %>%
  distinct(longitude, latitude, locality_id, locality, locality_type, elevation) %>%
  filter(!is.na(elevation))

#### filter data ####

#'take a look at the counts
localityCount = count(dataLocs, locality)
#' quite some "localities" are simply coordinate pairs
#' keep localities with 5 or more points
dataLocsMultiN = left_join(dataLocs, localityCount, by = "locality") %>%
  filter(n >= 5)

#### Kmeans clsutering prior to KDE ####
centres = 20
#'do a simple k-means clustering with 20 centres
localityKmeans = kmeans(x = dataLocs[,c("longitude", "latitude")], centers = centres)

#'assign a cluster to each point
dataLocs$cluster = localityKmeans[["cluster"]]

#### prep for KDE ####
#'split by cluster
dataLocsMultiN = plyr::dlply(dataLocs, "cluster")

#### draw 95% kde for each ####
#'load ks and scales
library(ks); library(scales)
#'get the H.pi method working
#'
#'first make an empty list
localityKde = list()
#'run in loop:
#'1. first, the kde function for 90% kdes
#'2. then the contourLines function
#'3. then convert to polygon
#'4. convert the entire list to spatial polygons
library(sp)
for (i in 1:length(dataLocsMultiN)) {

  x = dataLocsMultiN[[i]]
  #'get the positions matrix
  pos = x[,c("longitude", "latitude")]
  #'get the plugin H
  H.pi = Hpi(x = pos)
  #'get the KDE
  clusterKDE = kde(pos, H = H.pi, compute.cont = T)
  #'draw contour lines
  contLines = contourLines(clusterKDE$eval.points[[1]], clusterKDE$eval.points[[2]],
                           clusterKDE$estimate, level = contourLevels(clusterKDE, 0.1))
  #'convert each to polygon
  contPoly = lapply(contLines, function(y) Polygon(y[-1]))
  #'make polygons
  contPolyN = Polygons(contPoly, paste("cluster", i, sep = "_"))
  #'make spatial polygon
  localityKde[[i]] = contPolyN
}

#'make full spatial polygons object
clusterPolygons = SpatialPolygons(localityKde, 1:centres)

#### make sf object and save as shapefile ####
#'make sf
library(sf)
clusterPolgonsSf = st_as_sfc(clusterPolygons)
#'write to shapefile
st_write(clusterPolgonsSf, dsn = "data/clusterPolygons", layer = "clusterPolygons", driver = "ESRI Shapefile", delete_dsn = TRUE)
