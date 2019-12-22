#### dataprep round 3 ####
#'in this round, we get a df where:
#'1. each locality_id is a row
#'2. each visit is a column with some values

#### separate by value into df list ####
#'each element of the list is one of:
#'1. duration, 2. distance, 3. julian date, 4. Nobservers, 5. timeStart
#'

library(tidyverse); library(readr)

#'load all data
data = read_csv("data/dataRand10.csv")
#'get a julian day for each day
data = mutate(data, jul.date = lubridate::yday(as.Date(observation_date)))

#'keep the useful columns, filter only black and orange flycatcher
dataSelected = select(data, scientific_name, sampling_event_identifier, locality_id, jul.date,
                    duration_minutes, effort_distance_km, number_observers,
                    time_observations_started, pres_abs,
                    expertise) %>% 
  # filter(scientific_name == "Ficedula nigrorufa") # comment out this filter to process all species
  filter(!is.na(expertise))

#'split into list by species
dataBySpecies = dataSelected %>% 
  plyr::dlply("scientific_name")

#'for each species, gather values, and assign a visit id 
dataGathered = dataBySpecies %>% 
  map(function(x) {
    x %>% 
      gather(variable, value, -locality_id, -sampling_event_identifier, -scientific_name) %>% 
      ungroup() %>% 
      group_by(locality_id, variable) %>% 
      mutate(visit = 1:length(value)) %>% 
      select(-sampling_event_identifier) #'removing sampling event identifier now
  })

#'split by variable
dataGathered = map(dataGathered, function(x){
  plyr::dlply(x, "variable")})

#'check that there are 41 species, each as a list element
assertthat::assert_that(length(dataGathered) == 50)

#### spread data over localities by visit ####
#'each date is taken to be a single visit
#'yet this need not be the case - two or more visits could have occurred on the same date
#'especially in heavily sampled areas.
#'taking the mean of the visits for such cases
#'
#'NB: NO LONGER TESTING, WILL RESULT IN A LARGE DATAFRAME
dataSpread = dataGathered %>% 
  unclass() %>% 
  map(function(x){
    map(x, function(y) {spread(y, visit, value, drop = F)})
  })

#### save as rdata for next phase ####
save(dataSpread, file = "dataSpread.rdata")

# end here2