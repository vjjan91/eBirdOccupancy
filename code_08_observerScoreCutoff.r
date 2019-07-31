#### code to look at which observers see species we want ####

rm(list = ls()); gc()

# get nilgiri checklists
library(data.table)
library(tidyverse)

#### data loading ####
# get ranef score data
ranefscore <- fread("data/dataObsRptrScore.csv")

# read in nilgiris data
ebd <- fread("data/dataForUse.csv")
# keep cols of interest
ebd <- setDF(ebd) %>% as_tibble() %>%
  mutate(year = year(observation_date)) %>% 
  select(observer = observer_id, year, 
         sei = sampling_event_identifier, scientific_name)

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

#### data handling ####
# who sees the most species
ebdSummary <- ebd %>% 
  inner_join(ranefscore) %>% 
  mutate(roundscore = plyr::round_any(rptrScore, 0.05)) %>% 
  group_by(roundscore, year) %>% 
  summarise(nchk = length(unique(sei)))# %>% 
  group_by(year) %>% 
  mutate(prop = nchk/sum(nchk))

# make plot
#plotObsScoreProp <- 
  ggplot(ebdSummary)+
  geom_tile(aes(x = year, y = roundscore, fill = prop))+
  scale_fill_viridis_c(option = "D", direction = -1, 
                       name = "proportion seen")+
  scale_x_continuous(breaks = c(2013:2018))+
  coord_cartesian(expand = F)+
  themeEbird()+
  # theme(legend.position = c(0.8, 0.1),
  #       legend.direction = "horizontal")+
  labs(y = "observer score")


# for each observer and year combination
# ask how many and which of the focal species were seen
# just bloody handle the data
ebdSoiSummary <- ebd %>% 
  inner_join(ranefscore) %>% 
  mutate(roundscore = plyr::round_any(rptrScore, 0.1)) %>% 
  filter(scientific_name %in% soi) %>% 
  count(scientific_name, year, roundscore) %>% 
  mutate(prop = n/sum(n)) %>% 
  group_by(scientific_name, year) %>% 
  mutate(prop = n/sum(n))

#### make plot####
source("ggThemeEbird.r")
plotSoiScore <- 
  ggplot(ebdSoiSummary)+
  geom_tile(aes(x = year, y = roundscore, fill = prop))+
  facet_wrap(~scientific_name)+
  scale_fill_viridis_c(option = "C", direction = -1, 
                       name = "proportion seen",
                      values = c(0.1, 1), na.value = "grey80",
                      breaks = seq(0.1, 0.8, 0.2))+
  scale_x_continuous(breaks = c(2013:2018))+
  coord_cartesian(expand = F)+
  themeEbird()+
  theme(legend.position = c(0.8, 0.1),
        legend.direction = "horizontal")+
  labs(y = "observer score")

# export
ggsave(plotSoiScore, filename = "figs/figSoiScore.png", width = 8, height = 8,
       device = png(), dpi = 300); dev.off()
