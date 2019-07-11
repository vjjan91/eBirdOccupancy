#### code to explore observer expertise ####

rm(list = ls()); gc()

# load libs and data
library(data.table)
library(tidyverse)
# read checklist covars
ebdChkSummary <- fread("data/eBirdChecklistVars.csv")
# read checklist species counts
ebdChkNsp <- fread("data/dataChecklistSpecies.csv")

# join and remove NAs
ebdChkSummary <- merge(ebdChkSummary, ebdChkNsp, by = "checklist_id",
                       all = FALSE, no.dups = T) %>% 
  setDF()

# count data points per observer 
obscount <- count(ebdChkSummary, observer) %>% filter(n >= 10)

# make factor and remove obs not in obscount
ebdChkSummary <- ebdChkSummary %>% 
  filter(observer %in% obscount$observer, 
         samplingEffort > 0) %>% 
  mutate(landcover = as.factor(landcover),
         observer = as.factor(observer)) %>% 
  drop_na() # remove NAs, avoids errors later

#### modelling species in checklist ####
# summarise the data

# construct a scam
library(gamm4)

# drop NAs to avoid errors
modNspecies <- gamm4(nSp ~ s(log(samplingEffort), k = 5) + 
                       s(decimalTime, bs = "cc") +
                       s(julianDate, bs = "cc") + 
                       landcover, 
                     random = ~(1|observer), 
                     data = ebdChkSummary, family = "poisson")

# save model object
save(modNspecies, file = "tempExpertiseData.rdata")

#### load model object and fit a curve ####
load("data/tempExpertiseData.rdata")

summary(modNspecies$gam)

# use predict method
setDT(ebdChkSummary)
ebdChkSummary[,predval:=predict(modNspecies$mer, type = "response")]
# round the effort to 10 min intervals
ebdChkSummary[,roundHour:=plyr::round_any(totalEff, 10, f = floor)]

# summarise the empval, predval grouped by observer and round10min
pltData <- ebdChkSummary[,.(prednspMean = mean(predval, na.rm = T),
             prednspSD = sd(predval, na.rm = T)),
          by=list(obs, roundHour)]

# get emp data mean and sd
pltDataEmp <- ebdChkSummary[,roundHour:=plyr::round_any(totalEff, 30, f = floor)
                        ][,.(empnspMean = mean(nSp),
                             empnspSd = sd(nSp)), by=list(roundHour)]

# plot and examine in base R plots
setDF(pltData)

# filter for 10 data points or more
pltData <- pltData %>% filter(obs %in% obscount$obs)  
# nest data
pltData <- tidyr::nest(pltData, -obs)

# get limits
xlims = c(0, 600); ylims = c(0, 100)
# set up plot
{pdf(file = "figs/figNspTime.pdf", width = 6, height = 6)
  plot(0, xlim = xlims, ylim = ylims, type = "n", 
       xlab = "total effort (mins)", ylab = "N species")
  # plot in a loop
  for(i in 1:nrow(pltData)){
    df = pltData$data[[i]]
    lines(df$roundHour, df$prednspMean, col=alpha(rgb(0,0,0), 0.01))
  }
  
  # add emp data points
  points(pltDataEmp$empnspMean~pltDataEmp$roundHour, col = 1)
  
  # add error bars
  arrows(pltDataEmp$roundHour, pltDataEmp$empnspMean+pltDataEmp$empnspSd, pltDataEmp$roundHour, pltDataEmp$empnspMean-pltDataEmp$empnspSd, col = 1, code=3, angle = 90, length = 0.05)
  dev.off()
  
}

#### get observer scores as n species at 1 hour ####
ebdNspPred <- ebdChkSummary %>% 
  mutate(totalEff = 60) %>% 
  distinct(obs, checklist_id, totalEff, startTime, meanDate, land, nLand)
