#### code to explore observer expertise ####

rm(list = ls()); gc()

# load libs and data
library(data.table)
library(magrittr); library(dplyr); library(tidyr)

# get ci func
ci <- function(x){qnorm(0.975)*sd(x, na.rm = T)/sqrt(length(x))}

# read checklist covars
ebdChkSummary <- fread("data/eBirdChecklistVars.csv")

# change names
setnames(ebdChkSummary, c("sei", "observer","year", "duration", "distance",
                          "longitude", "latitude", "decimalTime",
                          "julianDate", "nObs", "nSp", "landcover"))

# count data points per observer 
obscount <- count(ebdChkSummary, observer) %>% filter(n >= 10)

# make factor variables and remove obs not in obscount
# also remove 0 durations
ebdChkSummary <- ebdChkSummary %>% 
  filter(observer %in% obscount$observer, 
         duration > 0) %>% 
  mutate(landcover = as.factor(landcover),
         observer = as.factor(observer)) %>% 
  drop_na() # remove NAs, avoids errors later

# save model object
save(modNspecies, file = "data/modExpertiseData.rdata")

#### repeatability model for observers ####
library(scales)
# cosine transform the decimal time and julian date
ebdChkSummary <- setDT(ebdChkSummary)[,`:=`(timeTrans = 1 - cos(12.5*decimalTime/max(decimalTime)),
                           dateTrans = cos(6.25*julianDate/max(julianDate)))
                     ][,`:=`(timeTrans = rescale(timeTrans, to = c(0,6)),
                             dateTrans = rescale(dateTrans, to = c(0,6)))]

# get a subset
ebdChkSummary <- ebdChkSummary[year >= 2013,] %>% sample_n(1e4)


# uses a subset of data
library(rptR)
modObsRep <- rpt(nSp ~ log(duration) + timeTrans + dateTrans + landcover +
                   (1|observer), grname = "observer", data = ebdChkSummary, nboot = 100, npermut = 0, datatype = "Poisson")


#### load model object and get ranef scores ####
load("data/modExpertiseData.rdata")

summary(modNspecies$mer)

# get the ranef coefficients as a measure of observer score
obsRanef <- lme4::ranef(modNspecies$mer)[[1]]
# make datatable
setDT(obsRanef, keep.rownames = T)[]
# set names
setnames(obsRanef, c("observer", "ranefScore"))
# scale ranefscore between 0 and 1
obsRanef[,ranefScore:=scales::rescale(ranefScore)]

#### plot diagnostics ####
# how many species on average per obs score?

# attach score to chksummary
ebdChkSummary <- setDT(ebdChkSummary)[obsRanef, on=.(observer)]

# get plot
ebdObsScore <- ebdChkSummary[,.(meanSp = mean(nSp, na.rm = T),
                 ciSp = ci(nSp)) ,by=list(observer, ranefScore)]
library(ggplot2)
ggplot(ebdSpScore)+
  geom_point(aes(ranefScore, meanSp), 
                 #     ymin = meanSp-ciSp, ymax = meanSp + ciSp),
                  size = 0.5, alpha = 0.2)

# export observer ranef score
fwrite(ebdObsScore, file = "data/dataObsRanefScore.csv")

# end here
