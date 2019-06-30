#### code to explore observer expertise ####

# load libs and data
library(data.table)

ebdNspChk <- fread("data/eBirdChecklistSpecies.csv")

# remove NAs - leaves around 210k points
ebdNspChk <- na.omit(ebdNspChk)

# makde factor
ebdNspChk[,landcover:=as.factor(landcover)]

# summarise
ebdNspSum <- ebdNspChk[,.(totalEff = sum(samplingEffort),
                    totalDist = sum(samplingDistance),
                    startTime = min(decimalTime),
                    meanDate = mean(julianDate),
                    nSp = sum(N),
                    nLand = length(unique(landcover)),
                    obs = first(observer)), by=checklist_id]

# choosing covariates from Kelling et al. 2015
# covariates reflect different classes of peredictors
# 1. variability in the species richness (time of year and habitat)
# 2. variability in species habits (time of day and effort)
# 3. observer effect (obsever id)

# plot data to explore
library(ggplot2)
library(dplyr); library(tidyr)

ebdNspChk %>% 
  filter(samplingEffort <= 60 * 10,
         samplingDistance <= 25) %>%  #assumed km
  select_if(is.numeric) %>% 
  gather(variable, value) %>% 
ggplot()+
  geom_histogram(aes(x = value))+
  facet_wrap(~variable, scales = "free_x")

ggsave(filename = "figHistCovars.png", device = png(), height = 6, width = 6); dev.off()


#### modelling species in checklist ####
# try a poisson GLM per Johnston et al. 2018
# library(lme4)
# 
# modNspecies <- glmer(N ~ log(samplingEffort) + 
#                        log(julianDate) + log(julianDate^2)+
#                        decimalTime +
#                        (1|observer) + (1|landcover),
#                      data = ebdNspChk %>% dplyr::sample_n(1e3), family = poisson)
# 
# library(sjPlot)
# plot_model(modNspecies)

# summarise the data
# sum the samplingEffort, samplingDistance, mean of decimalTime, julianDate, lat, long, sum of N, sum of unique landcovers

library(tibble)
ebdNspSum <- as_tibble(setDF(ebdNspSum))
ebdNspSum$obs <- as.factor(ebdNspSum$obs)

# construct a scam
library(scam)
library(mgcv)
library(gamm4)

modNspecies <- gamm4(nSp ~ s(totalEff) + s(startTime), data = ebdNspSum, random = ~(1|obs))

plot.scam(modNspecies, shift = coef(modNspecies)[1], shade = TRUE)

summary(modNspecies)
