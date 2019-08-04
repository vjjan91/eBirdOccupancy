#### code for checklists over time in kerala ####

# how badly did kerala flooding in 2018 affect eBird reporting?

# load libs and data
library(data.table)
ebd <- fread("data/dataForUse.csv")

# count checklists per julian day per year
ebd <- ebd[,year:=year(observation_date)
           ][,.(nchk = length(unique(checklist_id))), by = list(year, julianDate)]


# plot over time
library(ggplot2)
source("ggThemeEbird.r")
ggplot(ebd)+
  geom_line(aes(julianDate, nchk))+
  facet_wrap(~year)+
  themeEbird()

# export
ggsave("figs/figChkPerDay.png", units = "in", height = 3, width = 6, device = png(), dpi = 300)
