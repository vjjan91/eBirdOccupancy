#### code to explore observer expertise ####

# load libs and data
library(data.table)

ebdNspChk <- fread("data/eBirdChecklistSpecies.csv")

# remove NAs - leaves around 210k points
ebdNspChk <- na.omit(ebdNspChk)

# makde factor
ebdNspChk[,landcover:=as.factor(landcover)]

library(tibble)
ebdNspChk <- as_tibble(ebdNspChk)

# choosing covariates from Kelling et al. 2015
# covariates reflect different classes of peredictors
# 1. variability in the species richness (time of year and habitat)
# 2. variability in species habits (time of day and effort)
# 3. observer effect (obsever id)

# plot data to explore
library(ggplot2)

ggplot()+
  geom_histogram(data = ebdNspChk, aes(x = decimalTime, y = ..density..))

# fit a poisson GLM per Johnston et al. 2018
library(lme4)

modNspecies <- glmer(N ~ log(samplingEffort) + 
                       log(julianDate) + log(julianDate^2)+
                       decimalTime +
                       (1|observer) + (1|landcover),
                     data = ebdNspChk %>% dplyr::sample_n(1e3), family = poisson)

library(sjPlot)
plot_model(modNspecies)
