#### code to explore observer expertise ####

rm(list = ls()); gc()

# load libs and data
library(data.table)
library(magrittr); library(dplyr); library(tidyr)
library(readxl)

# get ci func
ci <- function(x){qnorm(0.975)*sd(x, na.rm = T)/sqrt(length(x))}

# read checklist covars
ebdChkSummary <- fread("data/eBirdChecklistVars.csv")

# change names
setnames(ebdChkSummary, c("sei", "observer","year", "duration", "distance",
                          "longitude", "latitude", "decimalTime",
                          "julianDate", "nObs", "nSp", "nSoi", "landcover"))

# count data points per observer 
obscount <- count(ebdChkSummary, observer) %>% 
  filter(n >= 10)

# make factor variables and remove obs not in obscount
# also remove 0 durations
ebdChkSummary <- ebdChkSummary %>% 
  filter(observer %in% obscount$observer, 
         duration > 0,
         nSoi > 0,
         !is.na(nSoi)) %>% 
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
library(lme4)
modObsRep <- rpt(nSoi ~ log(duration) + 
                   sqrt(decimalTime) + 
                   I((sqrt(decimalTime))^2) + 
                   log(julianDate) + 
                   I((log(julianDate)^2)) + 
                   (1|observer), 
                 nboot = 10,
                 data = ebdChkSummary,
                 grname = "observer",
                 datatype = "Gaussian")
# modObsRep <- rpt(nSoi ~ duration + decimalTime + julianDate + landcover + (1|year) + (1|observer), grname = c("observer"), data = ebdChkSummary, nboot = 100, npermut = 0, datatype = "Poisson")
# examine observer repeatability
modObsRep

# save model object
save(modObsRep, file = "data/modObsRepeat.rdata")

#### write model output to file ####
# make dir if absent
if(!dir.exists("data/modOutput")){
  dir.create("data/modOutput")
}

# write model output to text file
{writeLines(R.utils::captureOutput(list(Sys.time(), summary(modObsRep))), 
            con = "data/modOutput/modOutExpertise.txt")}

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

#### plot histogram ####
hist(obsRanef$rptrScore)
count(obsRanef, rptrScore < 0.5)

# # remove score below 0.5 and rescale
# obsRanef <- obsRanef[rptrScore >= 0.5,
#                      ][,rptrScore:=rescale(rptrScore)]
# hist again
hist(obsRanef$rptrScore)

# plot in landcover classes
obsRanef <- merge(ebdChkSummary[,c("observer", "landcover","year")], obsRanef, by = c("observer"))

library(ggplot2)

ggplot(obsRanef)+
  geom_histogram(aes(x = rptrScore, group = landcover))+
  facet_wrap(~landcover, scales = "free", labeller = label_both)+
  scale_y_continuous(labels = scales::comma,
                     breaks = scales::pretty_breaks(n = 4))+
  # ggthemes::theme_clean()+
  labs(x = "expertise", y = "count", 
       title = "observer expertise in landcover classes",
       subtitle = "restricted species list 13-11-19",
       caption = Sys.time())

ggsave("figs/fig_histObsExp_landcover_correctscore.png", device = png(), width = 11, height = 8, units = "in",
       dpi = 300)
dev.off()

#### export observer ranef score ####
fwrite(obsRanef[,.(observer, rptrScore)], file = "data/dataObsRptrScore.csv")

# end here
