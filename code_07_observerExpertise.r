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
                     data = ebdNspSum, family = "poisson")

summary(modNspecies$mer)

# save model object
save(modNspecies, file = "tempExpertiseData.rdata")

#### load model object and fit a curve ####
load("data/tempExpertiseData.rdata")

summary(modNspecies$gam)

# use predict method
setDT(ebdNspSum)
ebdNspSum[,predval:=predict(modNspecies$gam)]
# round the effort to 10 min intervals
ebdNspSum[,roundHour:=plyr::round_any(totalEff/60, 0.5, f = floor)]

# summarise the empval, predval grouped by observer and round10min
pltData <- ebdNspSum[,.(prednspMean = mean(predval, na.rm = T),
             prednspSD = sd(predval, na.rm = T)),
          by=list(obs, roundHour)]

{# plot and examine in base R plots
setDF(pltData)

# filter for 10 data points or more
pltData <- pltData %>% filter(obs %in% obscount$obs)  

# get limits
xlims = c(0, 5); ylims = c(0, 100)
# set up plot
plot(0, xlim = xlims, ylim = ylims, type = "n", 
     xlab = "total effort (mins)", ylab = "N species")
# nest data
pltData <- tidyr::nest(pltData, -obs)
# plot in a loop
for(i in 1:nrow(pltData)){
  df = pltData$data[[i]]
  lines(df$roundHour, df$prednspMean, col=alpha(rgb(0,0,0), 0.1))
}

}

#### get observer scores as n species at 1 hour ####
ebdNspPred <- ebdNspSum %>% 
  mutate(totalEff = 60) %>% 
  distinct(obs, checklist_id, totalEff, startTime, meanDate, land, nLand)
