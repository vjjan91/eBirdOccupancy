
#### supplement-----
#### obtain elevational limits based on presence data at 2.5km and 10km

# load library
library(dplyr)
library(data.table)

# load data
dat <- fread("C:\\Users\\vr235\\Desktop\\Occupancy Runs\\output\\04_data-covars-10km.csv")
names(dat)

# getting elevational limits (based on detections of each species at min elev and max elev)
# please note that this varies a little when calculated at 2.5km and 10km
elev_lim <- NULL

for(i in 1:length(unique(dat$scientific_name))){
  
  data <- dat %>% filter(dat$scientific_name==unique(dat$scientific_name)[i])%>%
    filter(pres_abs==1)
  presences <- count(data)
  elev_lim <- rbind(elev_lim, data.frame((unique(dat$scientific_name)[i]),presences,
                           broom::tidy(summary(data$elev))))
}

names(elev_lim) <- c("scientific_name","nPres","minimum",
                     "q1","median","mean","q3","maximum")

write.csv(elev_lim, "C:\\Users\\vr235\\Desktop\\Occupancy Runs\\output\\elev-summary-10km.csv", row.names=F)
