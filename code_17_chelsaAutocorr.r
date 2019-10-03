#### code to examine spatial autocorrelation ####

# load libs
library(raster)
library(gstat)

# list data
data = list.files("data/chelsa/", pattern = "crop.tif", full.names = TRUE)

# make raster list
envdata <- purrr::map(data, raster)

#'make custom functiont to convert matrix to df
funcRasterToDf <- function(inp) {
  
  # assert is a raster obj
  assertthat::assert_that("RasterLayer" %in% class(inp),
                          msg = "input is not a raster")
  
  # get raster resolution
  inpres = res(inp)
  
  raster::as.matrix(inp) %>%
    as.data.frame() %>% 
    `colnames<-`(1:ncol(.)) %>% 
    mutate(y = 1:dim(.)[1]) %>% 
    gather(x, val, -y) %>% 
    mutate(x = as.numeric(x)*inpres,
           y = y*inpres)
}

# load lib
library(tibble); library(purrr); library(dplyr); library(tidyr)
# convert each matrix to df
envdataDf <- tibble(variable = map_chr(envdata, names),
                    data = map(envdata, funcRasterToDf))

# prep new variogram column
envdataDf <- envdataDf %>% 
  mutate(vgram = map(data, function(z){
    gstat::variogram(val~1, loc=~x+y, data = z %>% drop_na())
  }))

# save temp
save(envdataDf, file = "data/chelsa/chelsaVariograms.rdata")

# plot variograms in a list
{
  png(filename = "figs/figChelsaVgrams.png", height = 800, width = 800*1.5,
      res = 150);
  par(mfrow = c(2,3))
  map2(envdataDf$vgram, envdataDf$variable, function(d1, d2){
    plot(d1$dist, d1$gamma, pch = 16, 
         type = "b", 
         xlab = "pairwise distance (degrees)",
         ylab = "semivariance",
         main = d2)
  })
  dev.off()
}
