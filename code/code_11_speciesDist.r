#### species distributions ####

library(data.table)
library(magrittr)

# get soi to filter data
# get soi names
soi <- c("Anthus nilghiriensis",
         "Montecincla cachinnans",
         "Montecincla fairbanki",
         "Sholicola albiventris",
         "Sholicola major",
         "Culicicapa ceylonensis",
         "Pomatorhinus horsfieldii",
         "Ficedula nigrorufa",
         "Pycnonotus jocosus",
         "Iole indica",
         "Hemipus picatus",
         "Saxicola caprata",
         "Eumyias albicaudatus",
         "Rhopocichla atriceps")

# load data
data <- fread("data/dataForUse.csv")[scientific_name %in% soi,
                                     ][,year:=year(observation_date)
                                       ][year >= 2013,]

# split by species, year, and plot rounded proportions
data <- data %>% st_as_sf(coords = c("longitude","latitude")) %>% 
  `st_crs<-`(4326) %>% st_transform(32643)

# add UTM coordinate columns
data <- cbind(data, st_coordinates(data)) %>%
  st_drop_geometry() %>% setDT()

# round coordinates
data <- data[,`:=`(xround = plyr::round_any(X, 1e4),
           yround = plyr::round_any(Y, 1e4),
           observation_count = ifelse(observation_count == "X", 1, observation_count))
     ][,observation_count:=as.numeric(observation_count)
       ][,.(count=sum(observation_count)), 
         by = list(scientific_name, xround, yround)
         ][,prop:=count/sum(count), by = list(scientific_name)]

#### load spatials ####
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

#### plot data ####
source("ggThemeEbird.r")

plotDistributions <- 
  ggplot(wg)+
  geom_sf(data = land, fill = "grey99", col = "transparent")+
  geom_tile(data = data,
            aes(xround, yround, fill = prop))+
  geom_sf(fill = "transparent", col = "grey80", lwd = 0.1)+
  
  scale_fill_viridis_c(option = "C", direction = -1)+
  scale_alpha_continuous(range = c(1, 0))+
  
  facet_wrap(~scientific_name, ncol = 4)+
  
  coord_sf(xlim=c(bbox["xmin"], bbox["xmax"]),
           ylim=c(bbox["ymin"], bbox["ymax"]), expand = F)+
  
  themeEbird()+
  theme(panel.background = element_rect(fill = "lightblue"),
        legend.position = "top")+
  labs(x = "longitude", y = "latitude", fill="prop. observations")

# export data
ggsave(plotDistributions, filename = "figs/figDistributions.png", 
       height = 10, width = 10, device = png(), dpi = 300); dev.off()
