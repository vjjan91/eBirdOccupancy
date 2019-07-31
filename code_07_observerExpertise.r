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
                          "julianDate", "nObs", "nSp", "nSoi", "landcover"))

# count data points per observer 
obscount <- count(ebdChkSummary, observer) %>% filter(n >= 10)

# make factor variables and remove obs not in obscount
# also remove 0 durations
ebdChkSummary <- ebdChkSummary %>% 
  filter(observer %in% obscount$observer, 
         duration > 0) %>% 
  mutate(landcover = as.factor(landcover),
         observer = as.factor(observer)) %>% 
  tidyr::drop_na() # remove NAs, avoids errors later

#### repeatability model for observers ####
library(scales)

# cosine transform the decimal time and julian date
ebdChkSummary <- setDT(ebdChkSummary)[duration <= 300,
                                        ][,`:=`(timeTrans = 1 - cos(12.5*decimalTime/max(decimalTime)),
                                                dateTrans = cos(6.25*julianDate/max(julianDate)))
                                          ][,`:=`(timeTrans = rescale(timeTrans, to = c(0,6)),
                                                  dateTrans = rescale(dateTrans, to = c(0,6)))]

# uses either a subset or all data
library(rptR)
modObsRep <- rpt(nSp ~ log(duration) + timeTrans + dateTrans + landcover + (1|year)+
                   (1|observer), grname = c("observer"), data = ebdChkSummary, nboot = 10, npermut = 0, datatype = "Poisson")

# examine observer repeatability
modObsRep

# save model object
save(modObsRep, file = "data/modObsRepeat.rdata")

#### load model object and get ranef scores ####
load("data/modObsRepeat.rdata")

# get the ranef coefficients as a measure of observer score
obsRanef <- lme4::ranef(modObsRep$mod)[[1]]

# make datatable
setDT(obsRanef, keep.rownames = T)[]
# set names
setnames(obsRanef, c("observer", "rptrScore"))

# scale ranefscore between 0 and 1
obsRanef[,rptrScore:=scales::rescale(rptrScore)]

#### soi seen per expertise ####
# how many soi on average per obs score?

# attach score to chksummary
ebdChkSummary <- setDT(ebdChkSummary)[obsRanef, on=.(observer)]

# get plot
ebdObsScore <- ebdChkSummary[,roundscore := plyr::round_any(rptrScore, 0.05)
                             ][,.(meanSoi = mean(nSoi, na.rm = T),
                 ciSoi = ci(nSoi)), by=list(roundscore)]
library(ggplot2)
ggplot(ebdObsScore)+
  geom_pointrange(aes(roundscore, meanSoi, ymin=meanSoi-ciSoi, ymax=meanSoi+ciSoi), 
                 #     ymin = meanSp-ciSp, ymax = meanSp + ciSp),
                  size = 0.5, col = "grey40")#+
#  scale_y_sqrt()

# export observer ranef score
fwrite(ebdObsScore, file = "data/dataObsRptrScore.csv")

# end here
