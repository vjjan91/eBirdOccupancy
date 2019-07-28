#### code to look at which observers see species we want ####

rm(list = ls()); gc()

# get species of interest list
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

# get nilgiri checklists
library(data.table)
library(tidyverse)

# read in shapefile of wg to subset by bounding box
library(sf)
wg <- st_read("hillsShapefile/WG.shp"); box <- st_bbox(wg)

# read in data and subset
ebd = fread("ebd_Filtered_May2018.txt")[between(LONGITUDE, box["xmin"], box["xmax"]) & between(LATITUDE, box["ymin"], box["ymax"]),]

# make new column names
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
setnames(ebd, newNames)

# keep useful columns
columnsOfInterest <- c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- dplyr::select(ebd, dplyr::one_of(columnsOfInterest))

gc()

# get the checklist id as SEI or group id
ebd[,checklist_id := ifelse(group_identifier == "", 
                            sampling_event_identifier, group_identifier),]

# get number of species of interest seen per SEI
dataSoi <- ebd[,.(totSoiSeen = length(intersect(scientific_name, soi))), 
               by=list(observer_id)]

setnames(dataSoi, c("observer", "soiSeen"))

#### count obs within nilgiris ####
# load nilgiris
nl <- st_read("hillsShapefile/Nil_Ana_Pal.shp"); box <- st_bbox(nl)

# read in data and subset
ebdNlSum <- ebd[between(longitude, box["xmin"], box["xmax"]) & between(latitude, box["ymin"], box["ymax"]),]

# count obs now and keep obs with 10 or more
ebdNlSum <- ebdNlSum[,.(nchk = length(unique(sampling_event_identifier))), 
                     by = observer_id][nchk >= 10,]
# change colnames
setnames(ebdNlSum, c("observer", "nchk"))

# add species seen and expertise score
obsRanefScore <- fread("data/dataObsRanefScore.csv")
dataSoi <- dataSoi[ebdNlSum, on = .(observer =observer)
                   ][obsRanefScore, on=.(observer = observer)]
dataSoi <- na.omit(dataSoi)

# make plot data
pltdata <- dataSoi[,.(meanSoi = mean(soiSeen),
                      ciSoi = 1.96*sd(soiSeen)/sqrt(length(soiSeen))),
                   by= .(plyr::round_any(ranefScore, 0.02))]

setnames(pltdata, c("ranefScore","meanSoi","ciSoi"))

# plot soiSeen ~ obsScore
ggplot(pltdata)+
  geom_pointrange(aes(ranefScore, meanSoi, ymin = meanSoi - ciSoi,
                      ymax = meanSoi+ciSoi),
                  col = "grey40")+
  theme_classic()+
  ylim(0, 10)+ xlim(0.2, 0.8)+
  labs(x = 'ranef explorer score',
       y = "# species of interest seen")

ggsave("figs/figSoiSeenVsScore.png", width = 6, height = 6,
       units = "in", dpi = 150)
dev.off()

# ends here
