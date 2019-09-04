#### code diversity change ####

# load libs
library(data.table)

# load data for wg
data = fread("data/dataWGbboxMid2018.csv")

# get chk and long lat
chk = dplyr::distinct(data, checklist_id, longitude, latitude)

# transform to utm
library(sf)
chk = st_as_sf(chk, coords = c("longitude", "latitude"))
chk = `st_crs<-`(chk, 4326) %>% st_transform(32643)  

# filter by wg
wg = st_read("hillsShapefile/WG.shp")
wg = st_transform(wg, 32643)
chk1 = as.numeric(st_intersects(chk, wg))
chk$keep = !is.na(chk1)
# make df again
chk = cbind(st_coordinates(chk), st_drop_geometry(chk))

# bind to data
data = merge(data, chk)[keep == T,]

# write
fwrite(data, file = "data/dataWgStrict.csv")

# count individuals per cell per year
sm = data[,`:=`(xround = plyr::round_any(X, 1e4),
                yround = plyr::round_any(Y, 1e4),
                year = year(observation_date),
                observation_count = as.numeric(ifelse(observation_count == "X", 1, observation_count)))
          ][,.(ncount = sum(observation_count)),
          by = list(xround, yround, year, scientific_name)]

# get total effort
eff = setDT(data)[,`:=`(xround = plyr::round_any(X, 1e4),
                 yround = plyr::round_any(Y, 1e4),
                 year = year(observation_date))] %>% 
  setDF() %>% 
  distinct(xround, yround, year, checklist_id, duration_minutes) %>% 
  drop_na() %>% 
  group_by(xround, yround, year) %>% 
  summarise(toteff = sum(duration_minutes, na.rm = T)) %>% 
  group_by(xround, yround) %>% 
  mutate(deff = c(NA, diff(toteff)))

setDT(data)
# add to sm
sm = merge(sm, eff, no.dups = T)

# get proportional observations anc counts
sm = sm[,effprop := toteff/sum(toteff), by = year
        ][,`:=`(totcount = sum(ncount),
          countprop = ncount/sum(ncount)),
        by = list(year, scientific_name)]

# sm = melt(sm, id.vars = c("year","xround","yround"), variable.name = "measure", value.name = "val")
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

# not rare species
library(stringr)
# soi2 = sm[,.N, by = list(scientific_name, year)][N > 10,][str_match(scientific_name, "sp.")[,1] != "sp." |
#                                                     is.na(str_match(scientific_name, "sp.")[,1]),]

# subset by soi for now
library(dplyr)
library(tidyr)
library(purrr)

# set.seed(0)
# soi3 = c(sample(unique(soi2$scientific_name), 20, replace = F), soi)

# plot change in species proportion and checklist proportion per cell
plotdata = sm[scientific_name %in% soi,] %>% 
  setDF() %>% 
  group_by(scientific_name) %>% 
  nest() %>% 
  mutate(data = map(data, function(df){
    group_by(df, xround, yround) %>% 
      mutate(dcount = c(NA, diff(countprop)),
             deff = c(NA, diff(toteff)))
  })) %>% 
  unnest()

# plot
library(ggplot2)
source("ggThemeEbird.r")
ggplot(plotdata)+
  geom_vline(xintercept = 0, col = 2, lty = 2)+
  geom_hline(yintercept = 0, col = 2, lty = 2)+
  geom_point(aes(deff/60, dcount), size = 0.3)+
  geom_smooth(aes(deff/60, dcount), method = "glm", lwd = 0.3)+
  facet_wrap(~scientific_name, scales = "free")+
  scale_x_continuous(labels = scales::comma)+
  # scale_y_continuous(labels = scales::comma)+
  coord_cartesian(ylim = c(-0.05, 0.05), xlim = c(-100,100))+
  # geom_abline(slope = 1, col = 2)+
  #scale_fill_viridis_c()+
  theme_gray()+
  labs(x = "annual change in sampling effort per 10km cell (hrs)",
       y = "annual change in proportion of species observations")

ggsave("figs/figPropChange.png", device = png(), dpi = 300, width = 11, height = 8, units = "in")

# run model
library(lmerTest)

mod1 = lmer(dcount ~ dchk*scientific_name + (1|year),
             data = plotdata)
