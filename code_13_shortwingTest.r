#### test observers on shortwings ####

# testing the hypothesis that poor obsevers report albiventris where it's not

library(data.table)
library(magrittr)

# load data
data <- fread("data/dataForUse.csv")
# filter for sholicola
data <- data[!is.na(stringr::str_extract(scientific_name, "Sholicola")),]
# get palakkad from OSM: https://osm.org/go/yn2QcSeM-?node=345267997
palakkad <- c(76.6512469, 10.7691989)
# filter data above palakkad
data <- data[latitude >= palakkad[2],]

# load observer scores
scores <- fread("data/dataObsRptrScore.csv")
# add obs score to data
data <- merge(data, scores, by.x = "observer_id", by.y = "observer",
              all.y = F)

# compare reports of major and albiventris
datasum <- data[,year:=year(observation_date)
                ][,.N, by = list(observer_id, scientific_name, rptrScore,year)] %>% 
  spread(scientific_name, N)

# compare expertise of osbervers reporting major and albiventris
library(ggplot2)
source("ggThemeEbird.r")

ggplot(data)+
  geom_boxplot(aes(scientific_name, rptrScore))+
  themeEbird()

test = aov(rptrScore ~ scientific_name, data = data)
summary(test)

# no real difference between observers reporting albiventris or major
# in the nilgiris
