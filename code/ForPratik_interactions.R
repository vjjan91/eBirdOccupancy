# Load libraries
library(auk)
library(lubridate)
library(sf)
library(unmarked)
library(raster)
library(ebirdst)
library(MuMIn)
library(AICcmodavg)
library(fields)
library(tidyverse)
library(doParallel)
library(snow)
library(openxlsx)
library(data.table)
library(dplyr)

# Load example data

dat.scaled <- fread("data/scaledCovs_2.5km.csv",header=T)
setDF(dat.scaled)
head(dat.scaled)

clim_elev <- list()
top_clim_elev <- list()

data <- dat.scaled %>% 
  filter(dat.scaled$scientific_name==unique(dat.scaled$scientific_name)[10]) 

# Preparing data for the unmarked model
occ <- filter_repeat_visits(data, 
                            min_obs = 1, max_obs = 10,
                            annual_closure = FALSE,
                            n_days = 2200, # 6 years is considered a period of closure
                            date_var = "observation_date",
                            site_vars = c("locality_id"))

obs_covs <- c("min_obs_started", 
              "duration_minutes", 
              "effort_distance_km", 
              "number_observers", 
              "protocol_type",
              "expertise",
              "julian_date")

# format for unmarked
occ_wide <- format_unmarked_occu(occ, 
                                 site_id = "site", 
                                 response = "pres_abs",
                                 site_covs = c( "locality_id","lc_01.y","lc_02.y","lc_03.y", "lc_04.y",
                                                "lc_05.y", "lc_06.y", "lc_07.y","bio_4.y", "bio_17.y","bio_18.y", 
                                                "prec_interannual.y","alt.y"),
                                 obs_covs = obs_covs)

# Convert this dataframe of observations into an unmarked object to start fitting occupancy models
occ_um <- formatWide(occ_wide, type = "unmarkedFrameOccu")

model_clim <- occu(~min_obs_started+
                     julian_date +
                     duration_minutes + 
                     effort_distance_km + 
                     number_observers + 
                     protocol_type +
                     expertise~bio_4.y*alt.y + bio_17.y*alt.y + bio_18.y*alt.y +  
                     prec_interannual.y*alt.y, data = occ_um)
# Set up the cluster
clusterType <- if(length(find.package("snow", quiet = TRUE))) "SOCK" else "PSOCK"
clust <- try(makeCluster(getOption("cl.cores", 4), type = clusterType))

clusterEvalQ(clust, library(unmarked))
clusterExport(clust, "occ_um")

# Detection terms are fixed
det_terms <- c("p(duration_minutes)","p(effort_distance_km)", "p(expertise)","p(julian_date)","p(min_obs_started)",
               "p(number_observers)","p(protocol_type)")

clim_elev[[10]] <- pdredge(model_clim, clust, fixed = det_terms)
names(clim_elev)[10] <- unique(dat.scaled$scientific_name)[10] 

top_clim_elev[[10]] <- get.models(clim_elev[[10]], subset = delta <4, cluster = clust)
names(top_clim_elev)[10] <- unique(dat.scaled$scientific_name)[10] 

a <- model.avg(top_clim_elev[[10]], fit = TRUE)

# Plotting interactions
library(insight)
library(parameters)
library(MuMIn)
library(sjPlot)

# Update packages via github
tab_model(a)
