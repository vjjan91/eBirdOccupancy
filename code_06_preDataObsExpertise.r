# load libs
library(dplyr); library(data.table)
library(stringr)

# read in data with fread
ebd = fread("ebd_Filtered_May2018.txt")

# make new column names
newNames <- str_replace_all(colnames(ebd), " ", "_") %>%
  str_to_lower()
ebd <- ebd %>% `colnames<-`(newNames)

# keep useful columns
columnsOfInterest = c("checklist_id","scientific_name","observation_count","locality","locality_id","locality_type","latitude","longitude","observation_date","time_observations_started","observer_id","sampling_event_identifier","protocol_type","duration_minutes","effort_distance_km","effort_area_ha","number_observers","species_observed","reviewed","state_code", "group_identifier")

ebd <- select(ebd, one_of(columnsOfInterest))

gc()

library(ggplot2)

# count states
ebd[,.N,.(state_code)]
# plot barplot
png(filename = "figCountState.png", width = 600, height = 600); ebd[,.N,.(state_code)] %>% 
  ggplot()+geom_col(aes(state_code, N)); dev.off()

# get the checklist id as SEI or group id
ebd <- ebd[,checklist_id := ifelse(group_identifier == "", sampling_event_identifier, group_identifier),]

# n checklists per observer
ebdNchk <- ebd[,.(nChk = length(unique(checklist_id))), observer_id]

# get species per checklist and SEI (just in case)
ebdNspChck <- ebd[,.(nSp = .N, time = max(duration_minutes), observer = first(observer_id)), .(checklist_id, sampling_event_identifier)]

# write data to file
fwrite(ebdNspChck, file = "data/eBirdChecklistSpecies.csv")
fwrite(ebdNchk, file = "data/eBirdNchecklistObserver.csv")
