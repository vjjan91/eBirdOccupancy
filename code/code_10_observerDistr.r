#### code to look at observer disribution ####

# load libs
library(data.table)

# read checklist covars
ebdChkSummary <- fread("data/eBirdChecklistVars.csv")

# change names
setnames(ebdChkSummary, c("sei", "observer", "year", "duration", "distance",
                          "longitude", "latitude", "decimalTime",
                          "julianDate", "nObs", "nSp", "nSoi", "landcover"))

# read observer score and join to summary
scores <- fread("data/dataObsRptrScore.csv")
ebdChkSummary <- merge(ebdChkSummary, scores,
                       by.x = "observer", by.y = "observer",
                       all = FALSE, no.dups = TRUE)

#### summarise spatial data ####

# make year nested dfs for average score per grid cell
# using a 50km grid
# transform to 
library(sf)
data <- ebdChkSummary %>% st_as_sf(coords = c("longitude","latitude")) %>% 
  `st_crs<-`(4326) %>% st_transform(32643)
# add UTM coordinate columns
data <- cbind(data, st_coordinates(data))
# drop geometry
data <- st_drop_geometry(data)

# use a 50000m grid to summarise average obs score per year
dataSum <- setDT(data)[,`:=`(xround = plyr::round_any(X, 1e4),
                             yround = plyr::round_any(Y, 1e4))
                       ][,.(avgscore = mean(rptrScore, na.rm = T),
                            sdscore = sd(rptrScore, na.rm = T),
                            nobs = .N), 
                         by=list(year, xround, yround)]

# add wg shapefile and india coastline
wg <- st_read("data/spatial/hillsShapefile/Nil_Ana_Pal.shp") %>% 
  st_transform(32643)
# get bbox
bbox <- st_bbox(wg) %>% st_as_sfc() %>% st_buffer(50*1e3) %>% st_bbox()
# add land
library(rnaturalearth)
land <- ne_countries(scale = 50, type = "countries", continent = "asia",
                     country = "india",
                     returnclass = c("sf"))
# crop land
land <- st_transform(land, 32643) %>% st_crop(bbox)

# plot data
source("ggThemeEbird.r")

plotYearScore <-
  ggplot(wg)+
  geom_sf(data = land, fill = "grey99", col = "transparent")+
  geom_tile(data = dataSum %>% dplyr::filter(year >= 2007),
            aes(xround, yround, fill = avgscore))+
  geom_sf(fill = "transparent", col = "grey80", lwd = 0.1)+
  
  scale_fill_viridis_c(option = "C", direction = -1)+
  scale_alpha_continuous(range = c(1, 0))+
  facet_wrap(~year, ncol = 3)+
  
  coord_sf(xlim=c(bbox["xmin"], bbox["xmax"]),
           ylim=c(bbox["ymin"], bbox["ymax"]), expand = F)+
  
  themeEbird()+
  theme(panel.background = element_rect(fill = "lightblue"),
        legend.position = "top")+
  labs(x = "longitude", y = "latitude", fill="mean observer score")

# export plot
ggsave(plotYearScore, filename = "figs/figObsScorePerYear.png", 
       height = 6, width = 7, device = png(), dpi = 300); dev.off()

#### observer-year kdes ####
# nest data by observer year
# drop obsevers with fewer than 10 checklists
datakde <- setDT(data)[,nchk:=.N,by=list(observer, year)
                       ][nchk >= 10,] %>% 
  setDF() %>% 
  group_by(observer, year) %>% nest()

# get kdes
# raster masks all kinds of things
library(sp); library(raster)
library(adehabitatHR)
datakde$polygons <- pmap(list(datakde$data, datakde$observer, datakde$year), 
                    function(a,b,c){
                      tryCatch({
  # get points
  pts <- dplyr::select(a, X, Y) %>% 
    st_as_sf(coords = c("X","Y")) %>% 
    `st_crs<-`(32643)
  
  # get sp version of points
  pts <- as(pts, "Spatial")
  
  # get kde
  tempkde <- kernelUD(pts, h = "LSCV", grid = 60)
  
  # get 95% kde
  kde95 <- getverticeshr(tempkde, percent = 50)
  
  # make sf
  kde95 <- st_as_sf(kde95)
  
  print(glue::glue("kde {b} year {c} done"))
  
  return(kde95)},
  error = function(e){
    print(glue::glue("error in polygons for {b}"))
  })
})

# filter out bad polygons
datakde$tokeep <- map_dbl(datakde$polygons, function(z) "sf" %in% class(z))
# some 200 observers are removed
datakde <- filter(datakde, tokeep == 1)
# crop by landmass
datakde$polygons <- map(datakde$polygons, function(z){
  st_crop(z, land)
})

# get polygons
polys <- rbind_list(datakde$polygons) %>% 
  st_as_sf() %>% 
  bind_cols(datakde %>% dplyr::select(observer, year)) %>% 
  `st_crs<-`(32643)

# crop to better land
polys <- st_intersection(polys, land)

# export basic data
polydata <- polys %>% 
  st_drop_geometry() %>% 
  group_by(observer) %>% summarise(area = sum(area))

fwrite(polydata, file = "data/dataObsKdeScore.csv")

#### plot with overlaps ####
plotObsKde <- ggplot(polys %>% dplyr::filter(year >= 2013))+
  geom_sf(data = land, fill = "grey90", col = "transparent")+
  geom_sf(alpha = 0.02, aes(fill = area), col = "transparent")+
  geom_sf(data = wg, fill = "transparent", col = "grey80", lwd = 0.1)+
  scale_fill_viridis_c(option = "C")+
  facet_wrap(~year, ncol = 3)+
  themeEbirdMap()+
  coord_sf(crs = 4326)

# export plot
ggsave(plotObsKde, filename = "figs/figObsKde.png", 
       height = 7, width = 6, device = png(), dpi = 300); dev.off()

#### plot observer area vs ranef score ####
ranefscore <- fread("data/dataObsRanefScore.csv")[
  setDT(polydata), on = .(observer)
]

# plot data
plotObsScoreArea <- 
  ggplot(ranefscore)+
  geom_point(aes(ranefScore, area))+
  geom_smooth(aes(ranefScore, area))+
  scale_y_log10()+
  themeEbird()

ggsave(plotObsScoreArea, filename = "figs/figObsScoreArea.png", 
       height = 6, width = 6, device = png(), dpi = 300); dev.off()
