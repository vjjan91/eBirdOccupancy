#### code to explore observer expertise ####

# load libs and data
library(data.table)

ebdNspChk <- fread("data/eBirdChecklistSpecies.csv")

# remove NAs - leaves around 210k points
ebdNspChk <- na.omit(ebdNspChk)

# makde factor
ebdNspChk[,landcover:=as.factor(landcover)]

# summarise
# choosing covariates from Kelling et al. 2015
# covariates reflect different classes of peredictors
# 1. variability in the species richness (time of year and habitat)
# 2. variability in species habits (time of day and effort)
# 3. observer effect (obsever id)
ebdNspSum <- ebdNspChk[,.(totalEff = sum(samplingEffort),
                          totalDist = sum(samplingDistance),
                          startTime = min(decimalTime),
                          meanDate = mean(julianDate),
                          nSp = sum(N),
                          land = as.factor(first(landcover)),
                          nLand = length(unique(landcover)),
                          obs = first(observer)), by=checklist_id]

# count data points  
obscount <- count(ebdNspSum, obs) %>% filter(n >= 10)
# remove obs not in obscount
ebdNspSum <- ebdNspSum[obs %in% obscount$obs,]

# get frequency of nlandcovers sampled
dplyr::count(ebdNspSum, nLand)

#### modelling species in checklist ####
# summarise the data

library(tibble)
ebdNspSum <- as_tibble(setDF(ebdNspSum))
ebdNspSum$obs <- as.factor(ebdNspSum$obs)

# construct a scam
library(gamm4)

modNspecies <- gamm4(nSp ~ s(log(totalEff), k = 5) + 
                       s(startTime, bs = "cc") +
                       s(meanDate, bs = "cc") + land, 
                     random = ~(1|obs), 
                     data = ebdNspSum)

summary(modNspecies$mer)

save(modNspecies, file = "tempExpertiseData.rdata")

