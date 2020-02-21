#### code to look at which observers see species we want ####

rm(list = ls()); gc()

# get nilgiri checklists
library(data.table)
library(tidyverse)

# simple ci
ci <- function(x){
  qnorm(0.975)*sd(x, na.rm = T)/sqrt(length(x))
}

#### data loading ####
# get ranef score data
ranefscore <- read_csv("data/dataObsRptrScore.csv") %>% 
  distinct()

# plot ranef score dist
plotScoreDist <- ggplot(ranefscore)+
  geom_histogram(aes(rptrScore), fill = "white", col = 1)+
  labs(x = "observer score", y = "count", title = "distribution of observer scores")

# read in nilgiris data
ebd <- fread("data/dataForUse.csv")
# add year
ebd[,year:=year(observation_date)]

# get soi names
soifile <- readxl::read_excel("data/species_list_13_11_2019.xlsx")
soi <- soifile$scientific_name

#### soi per obs score ####
soi_obs <- read_csv(file = "data/dataChecklistSpecies.csv") %>% 
  left_join(ranefscore, by = c("observer_id" = "observer"))

# make plot of soi and nsp by score
soi_obs <- pivot_longer(soi_obs, cols = c("nSp", "totSoiSeen")) %>% 
  mutate(round_score = plyr::round_any(rptrScore, 0.05)) %>% 
  group_by(round_score, year, name) %>% 
  summarise_at(vars(value), .funs = list(~mean(.), ~ci(.)))

ggplot(soi_obs)+
  geom_pointrange(aes(round_score, mean, ymin = mean-ci, ymax=mean+ci, col = name),
                  shape = 1)+
  scale_colour_brewer(labels = c("total","SoI"), palette = "Dark2")+
  coord_cartesian(ylim=c(0,50))+
  facet_wrap(~year)+
  labs(x = "observer expertise (binsize = 0.05)", y = "species",
       caption = Sys.time(), col = "variable")

ggsave(filename = "figs/figNsp_Score.png", width = 8, height = 6, device = png(), dpi = 300); dev.off()

#### prop checklist reporting species ####
# what is the proportion of each observer's checklists per year
# in which each of the focal species appear?
ebdSoiSummary <- ebd[,.(nSei = length(unique(sampling_event_identifier))), by = list(observer_id, year)
                     ][ebd[scientific_name %in% soi, .N, 
                           by = list(observer_id, year, scientific_name)], 
                       on = c("observer_id", "year")
                       ][,propChk:=N/nSei]

# add observer score
ebdSoiSummary <- left_join(ebdSoiSummary, ranefscore, by = c("observer_id" = "observer"))

plotSoiPropChk <-
  ggplot(ebdSoiSummary)+
  geom_point(aes(x = rptrScore, y = propChk), 
            col = "grey40", size = 0.1, alpha = 0.5)+
  geom_smooth(aes(x = rptrScore, y = propChk), 
              method = "gam",
              formula = y~s(x, k = 2),
              col = 2, size = 0.5)+
  facet_wrap(~scientific_name)+
  # scale_fill_viridis_c(option = "C", direction = -1, 
  #                      name = "proportion of\n sightings contributed",
  #                     values = c(0, 1), na.value = "grey90",
  #                     breaks = seq(0, 1, 0.2))+
  # scale_x_continuous(breaks = c(2013:2018))+
  # scale_y_continuous(breaks = seq(0,1, 0.1))+
  coord_cartesian(ylim = c(0, 1), expand = T)+
  # theme(legend.position = c(0.8, 0.1),
  #       legend.direction = "horizontal")+
  labs(y = "proportion of checklists",
       x = "observer score",
       title = "prop. checklists reporting focal species ~ osberver score")

# export
ggsave(plotSoiPropChk, filename = "figs/figSoiScore.png", width = 11, height = 10, device = png(), dpi = 300); dev.off()

#### prop of sightings reported by score ####
# of all the reports of focal species, what proportion were reported
# by different observer scores?
ebdSoiProp <- ebd %>% 
  filter(scientific_name %in% soi) %>% 
  count(observer_id, scientific_name) %>% 
  group_by(observer_id) %>% 
  mutate(prop = n/sum(n)) %>% 
  left_join(ranefscore, by = c("observer_id" = "observer")) %>% 
  na.omit()

# plot
plotSoiPropObs <- ggplot(ebdSoiProp)+
  geom_point(aes(x = rptrScore, y = prop),
             col = "grey10", size = 0.1, alpha = 0.5)+
  geom_smooth(aes(x = rptrScore, y = prop),
              col = 4, size = 0.5, method = "gam",
              formula = y ~ s(x, k = 4))+
  facet_wrap(~scientific_name, scales = "free_y", drop = T)+
  scale_y_continuous(labels = scales::percent)+
  #coord_cartesian(ylim=c(0,0.02))+
  labs(x = "osberver score",
       y = "% observations",
       title = "prop. observations of focal species ~ observer score")

# export
ggsave(plotSoiPropObs, filename = "figs/figSoiProp.png", width = 12, height = 10, device = png(), dpi = 300); dev.off()

#### get panel plot ####
# prepare data for panel plot
ebdSoiProp <- ebd %>% 
  filter(scientific_name %in% soi) %>% 
  left_join(ranefscore, by = c("observer_id" = "observer")) %>% 
  mutate(roundscore = plyr::round_any(rptrScore, 0.1)) %>% 
  count(roundscore, scientific_name, year) %>% 
  group_by(scientific_name, year) %>% 
  mutate(prop = n/sum(n)) %>% 
  na.omit() %>% 
  full_join(crossing(scientific_name = soi, year = 2013:2018, roundscore = seq(0,1,0.1))) %>% 
  drop_na(scientific_name)

# make panel plot
plotPanelSoiProp <- ggplot(ebdSoiProp)+
  geom_tile(aes(year, roundscore, fill = prop))+
  facet_wrap(~scientific_name, drop = T)+
  
  scale_fill_viridis_c(option = "C", direction = -1)+
  scale_x_continuous(breaks = 2013:2018)+
  scale_y_continuous(breaks = seq(0, 1, 0.1))+
  theme(legend.position = "right",
        legend.key.width = unit(0.1, "cm"))+
  labs(x = "year", y = "binned expertise score",
       title = "prop. observations of focal species ~ binned score ~ year",
       fill = "prop. obsvtns")

# export
ggsave(plotPanelSoiProp, filename = "figs/figSoiPanelProp.png", width = 12, height = 10, device = png(), dpi = 300); dev.off()

# ends here
