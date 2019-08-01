#### code to look at which observers see species we want ####

rm(list = ls()); gc()

# get nilgiri checklists
library(data.table)
library(tidyverse)

#### data loading ####
# get ranef score data
ranefscore <- fread("data/dataObsRptrScore.csv")

# plot ranef score dist
plotScoreDist <- ggplot(ranefscore)+
  geom_histogram(aes(rptrScore), fill = "white", col = 1)+
  themeEbird()+
  labs(x = "observer score", y = "count", title = "distribution of observer scores")

# export
ggsave(plotScoreDist, filename = "figs/figScoreDist.png", width = 8, height = 8, device = png(), dpi = 300); dev.off()

# read in nilgiris data
ebd <- fread("data/dataForUse.csv")
# add year
ebd[,year:=year(observation_date)]

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

#### prop checklist reporting species ####
# what is the proportion of each observer's checklists per year
# in which each of the focal species appear?
ebdSoiSummary <- ebd[,.(nSei = length(unique(sampling_event_identifier))), by = list(observer_id, year)
                     ][ebd[scientific_name %in% soi, .N, 
                           by = list(observer_id, year, scientific_name)], 
                       on = c("observer_id", "year")
                       ][,propChk:=N/nSei]

# add observer score
ebdSoiSummary <- merge(ebdSoiSummary, ranefscore, by.x = "observer_id", by.y = "observer", all.y = FALSE, no.dups = TRUE)

source("ggThemeEbird.r")
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
  themeEbird()+
  # theme(legend.position = c(0.8, 0.1),
  #       legend.direction = "horizontal")+
  labs(y = "proportion of checklists",
       x = "observer score",
       title = "prop. checklists reporting focal species ~ osberver score")

# export
ggsave(plotSoiPropChk, filename = "figs/figSoiScore.png", width = 8, height = 8, device = png(), dpi = 300); dev.off()

#### prop of sightings reported by score ####
# of all the reports of focal species, what proportion were reported
# by different observer scores?
ebdSoiProp <- ebd[scientific_name %in% soi,
    ][,.N, by = list(observer_id, scientific_name),
          ][,prop:= N/sum(N), by = scientific_name
            ][ranefscore, on = c("observer_id" = "observer")] %>% 
  na.omit()

# plot
plotSoiPropObs <- ggplot(ebdSoiProp)+
  geom_point(aes(x = rptrScore, y = prop),
             col = "grey10", size = 0.1, alpha = 0.5)+
  geom_smooth(aes(x = rptrScore, y = prop),
              col = 4, size = 0.5, method = "gam",
              formula = y ~ s(x, k = 4))+
  facet_wrap(~scientific_name, scales = "free_y", drop = T)+
  scale_y_continuous(labels = percent)+
  coord_cartesian(ylim=c(0,0.02))+
  themeEbird()+
  labs(x = "osberver score",
       y = "% observations",
       title = "prop. observations of focal species ~ observer score")

# export
ggsave(plotSoiPropObs, filename = "figs/figSoiProp.png", width = 8, height = 8, device = png(), dpi = 300); dev.off()

#### get panel plot ####
ebdSoiProp <- ebd[ranefscore, on = c("observer_id" = "observer")
                  ][,roundscore := plyr::round_any(rptrScore, 0.1),
                    ][scientific_name %in% soi,
                      ][,.N, by = list(roundscore, scientific_name, year),
                        ][,prop:= N/sum(N), by = list(scientific_name,year)] %>% 
  na.omit() %>% 
  full_join(crossing(scientific_name = soi, year = 2013:2018, roundscore = seq(0,1,0.1))) %>% 
  drop_na(scientific_name)

plotPanelSoiProp <- ggplot(ebdSoiProp)+
  geom_tile(aes(year, roundscore, fill = prop))+
  facet_wrap(~scientific_name, drop = T)+
  
  scale_fill_viridis_c(option = "C", direction = -1)+
  scale_x_continuous(breaks = 2013:2018)+
  scale_y_continuous(breaks = seq(0, 1, 0.1))+
  
  themeEbird()+
  theme(legend.position = c(0.8, 0.1))+
  labs(x = "year", y = "binned expertise score",
       title = "prop. observations of focal species ~ binned score ~ year",
       fill = "prop. observations")

# export
ggsave(plotPanelSoiProp, filename = "figs/figSoiPanelProp.png", width = 8, height = 8, device = png(), dpi = 300); dev.off()