#### code to plot clustered localities in R ####
#'load libs
#'
library(tidyverse); library(sf); library(tmap)

#### read in the spatial data ####
#'read clustered location polygons
clusterPolygons = st_read("data/clusterPolygons/clusterPolygons.shp")
#'boundary of the ghats
hills = st_read("hillsShapefile/Nil_Ana_Pal.shp")
#'assign clusterPolygons the hills crs
st_crs(clusterPolygons) = st_crs(hills)

#### load elevation raster ####
library(raster)
#'read in the raster
elevation = raster("Elevation/alt/")
#'crop raster to hills
elevCrop = crop(elevation, as(st_buffer(hills, 0.05), "Spatial"))
rm(elevation); gc()

#'write cropped raster to file
writeRaster(elevCrop, filename = "data/elevationHills", format = "GTiff", overwrite = T)

#'re-read raster
elevCrop = raster("data/elevationHills.tif")

#'fix elevation values to be numeric
elevCrop@data@attributes[[1]]$category = as.numeric(elevCrop@data@attributes[[1]]$category)

#'write fixed raster to new file
#'write cropped raster to file
writeRaster(elevCrop, filename = "data/elevationHills2", format = "GTiff", overwrite = T)

#### make map using tmap ####
library(RColorBrewer); library(viridis)
library(colorspace)

mapClusters = tm_shape(elevCrop)+
  tm_grid(projection = "longlat", col = "grey90", labels.inside.frame =  T, n.x = 4, n.y = 4)+
  tm_raster(alpha = 0.5, palette = terrain_hcl(120), n = 10, style = "cont", title = "elevation")+

tm_shape(hills)+
  tm_borders(col = "black")+
  
tm_shape(clusterPolygons)+
  tm_polygons(col = "FID", border.col = "grey20", style = "cat", 
              palette = colorRampPalette(brewer.pal(12, name = "Spectral"))(20),
              alpha = 0.4, legend.show = F)+
  tm_layout(bg.color = "white", legend.position = c("right", "top"))
  
#### export clusters map ####
png(filename = "mapClusters.png", width = 800, height = 800, res = 200)
mapClusters
dev.off()
