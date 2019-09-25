#### code to aggregate landcover ####

library(raster)

# load data
landcover = raster("data/landUseClassification/Reprojected Image_UTM43N_31stAug_Ghats.tif")

# write function to aggregate
funcMode <- function(x, na.rm = T) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# a basic test
assertthat::assert_that(funcMode(c(2,2,2,2,3,3,3,4)) == as.character(2), 
                        msg = "problem in the mode function") # works

#### raster aggregation ####
rasterAgg = raster::aggregate(landcover, fact=10, fun = funcMode)

# aggregate some more
rasterAgg1km = raster::aggregate(landcover, fact=10, fun = funcMode)

# plot
x11();plot(rasterAgg1km, col = c("white",pals::kovesi.rainbow(7)))

# export rasters
raster::writeRaster(rasterAgg, filename = "data/spatial/landcover100m.tif", format = "GTiff")
raster::writeRaster(rasterAgg1km, filename = "data/spatial/landcover1km.tif", format = "GTiff")

#### compare rasters ####

# load new rasters
rasterAgg = raster("data/spatial/landcover100m.tif")
rasterAgg1km = raster("data/spatial/landcover1km.tif")

# map rasters
{
  x11()
  par(mfrow=c(2,2))
  plot(landcover, col = c("white", pals::kovesi.rainbow(7)))
  plot(rasterAgg1km, col = c("white", pals::kovesi.rainbow(7)))
  
  
}