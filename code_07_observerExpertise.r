#### code to explore observer expertise ####

rm(list = ls()); gc()

# load libs and data
library(data.table)
library(magrittr); library(dplyr); library(tidyr)

# get ci func
ci <- function(x){qnorm(0.975)*sd(x, na.rm = T)/sqrt(length(x))}

# read checklist covars
ebdChkSummary <- fread("data/eBirdChecklistVars.csv")[,roundobs:=NULL]

# change names
setnames(ebdChkSummary, c("sei", "observer", "duration", "distance",
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

#### modelling species in checklist ####
# summarise the data

# construct a scam
library(gamm4)

# drop NAs to avoid errors
modNspecies <- gamm4(nSp ~ s(log(duration), k = 5) + 
                       s(decimalTime, bs = "cc") +
                       s(julianDate, bs = "cc") + 
                       landcover, 
                     random = ~(1|observer), 
                     data = ebdChkSummary, family = "poisson")

# save model object
save(modNspecies, file = "data/modExpertiseData.rdata")

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
