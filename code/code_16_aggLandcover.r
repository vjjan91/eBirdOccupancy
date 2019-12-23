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
# aggregate at different levels in sequence
lc_100m <- aggregate(landcover, fact = 10, fun = funcMode)
lc_1km <- aggregate(lc_100m, fact = 10, fun = funcMode)
lc_10km <- aggregate(lc_1km, fact = 10, fun = funcMode)
lc_25km <- aggregate(lc_10km, fact = 2.5, fun = funcMode)

# write 10 and 25km
writeRaster(lc_10km, filename = "data/spatial/landcover10km.tif")
writeRaster(lc_25km, filename = "data/spatial/landcover25km.tif")

#### compare rasters ####

# load new rasters
library(dplyr)
{
  rasterAgg = raster("data/spatial/landcover100m.tif")
  rasterAgg1km = raster("data/spatial/landcover1km.tif")
}

# make raster barplot data
data1km = raster::getValues(rasterAgg1km); data1km = data1km[data1km > 0]; data1km = table(data1km); data1km = data1km/sum(data1km)

{
  data10m = raster::getValues(landcover); data10m = data10m[data10m > 0]
  data10m = tibble(value = data10m)
  data10m = dplyr::count(a, value) %>% dplyr::mutate(n=n/sum(n))
  data10m = xtabs(n~value, data10m)
}

# map rasters
{
  png(filename = "figs/figLandcoverResample.png", width = 1200, height = 1200,
      res = 150)
  par(mfrow=c(2,2))
  # rasterplots
  raster::plot(landcover, col = c("white", pals::kovesi.rainbow(7)), 
       main = "10m sentinel data", xlab = "longitude", y = "latitude")
  raster::plot(rasterAgg1km, col = c("white", pals::kovesi.rainbow(7)),
       main = "1km resampled data", xlab = "longitude", y = "latitude")
  
  # barplots
  barplot(data10m, xlab = c("landcover class"), ylab = "prop.",
          col = pals::kovesi.rainbow(7))
  barplot(data1km, xlab = c("landcover class"), ylab = "prop.",
          col = scales::alpha(pals::kovesi.rainbow(7), alpha =0.8), add = F)
  barplot(data10m, xlab = c("landcover class"), ylab = "prop.",
          col = "grey20", border = NA, density = 30, add = T)
  dev.off()
}

# ends here
