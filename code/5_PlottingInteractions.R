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
head(dat.scaled)

{clim_elev <- list()
top_clim_elev <- list()
clim_elev_imp <- list()
clim_elev_modelEst <- list()
clim_elev_avg <- list()}

data <- dat.scaled[scientific_name== "Copsychus fulicatus",]

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
clusterType <- if(length(find.package("snow", quiet = TRUE))) {"SOCK"} else {"PSOCK"}
clust <- try(makeCluster(getOption("cl.cores", 4), type = clusterType))

clusterEvalQ(clust, library(unmarked))
clusterExport(clust, "occ_um")

# Detection terms are fixed
det_terms <- c("p(duration_minutes)","p(effort_distance_km)", "p(expertise)","p(julian_date)","p(min_obs_started)",
               "p(number_observers)","p(protocol_type)")

clim_elev[[8]] <- pdredge(model_clim, clust, fixed = det_terms)
names(clim_elev)[8] <- unique(dat.scaled$scientific_name)[8] 

top_clim_elev[[8]] <- get.models(clim_elev[[8]], subset = delta <4, cluster = clust)
names(top_clim_elev)[8] <- unique(dat.scaled$scientific_name)[8] 

if(length(top_clim_elev[[8]])>1){
  c <- model.avg(top_clim_elev[[8]], fit = TRUE)
  clim_elev_avg[[8]] <- as.data.frame(c$coefficients) 
  names(clim_elev_avg)[8] <- unique(dat.scaled$scientific_name)[8]
  
  clim_elev_modelEst[[8]] <- data.frame(Predictor = rownames(coefTable(c, full = T)),
                                   Coefficient = coefTable(c, full = T)[,1],
                                   SE = coefTable(c, full = T)[,2],
                                   lowerCI = confint(c)[,1],
                                   upperCI = confint(c)[,2],
                                   z_value = (summary(c)$coefmat.full)[,3],
                                   Pr_z = (summary(c)$coefmat.full)[,4])
  names(clim_elev_modelEst)[8] <- unique(dat.scaled$scientific_name)[8]
  
  clim_elev_imp[[8]] <- as.data.frame(MuMIn::importance(c))
  names(clim_elev_imp)[8] <- unique(dat.scaled$scientific_name)[8]
} else {
  clim_elev_avg[[8]] <- as.data.frame(unmarked::coef(top_clim_elev[[8]][[1]]))
  names(clim_elev_avg)[8] <- unique(dat.scaled$scientific_name)[8] 
  
  lowSt <-  data.frame(lowerCI=confint(top_clim_elev[[8]][[1]], type="state")[,1])
  lowDet <- data.frame(lowerCI=confint(top_clim_elev[[8]][[1]], type="det")[,1])
  upSt <-  data.frame(upperCI=confint(top_clim_elev[[8]][[1]], type="state")[,2])
  upDet <- data.frame(upperCI=confint(top_clim_elev[[8]][[1]], type="det")[,2])
  zSt <-  data.frame(summary(top_clim_elev[[8]][[1]])$state[,3])
  zDet <- data.frame(summary(top_clim_elev[[8]][[1]])$det[,3])
  Pr_zSt <- data.frame(summary(top_clim_elev[[8]][[1]])$state[,4])
  Pr_zDet <- data.frame(summary(top_clim_elev[[8]][[1]])$det[,4])
  
  clim_elev_modelEst[[8]] <- data.frame(Predictor = rownames(coefTable(top_clim_elev[[8]][[1]])),
                                   Coefficient = coefTable(top_clim_elev[[8]][[1]])[,1],
                                   SE = coefTable(top_clim_elev[[8]][[1]])[,2],
                                   lowerCI = rbind(lowSt,lowDet),
                                   upperCI = rbind(upSt,upDet),
                                   z_value = rbind(zSt,zDet),
                                   Pr_z = rbind(Pr_zSt,Pr_zDet))
  
  names(clim_elev_modelEst)[8] <- unique(dat.scaled$scientific_name)[8]
  
}

# To be done:

# 1. Rename predictors and labels with their actual description. For eg. lc_06 is Proportion of Tea
# 2. Need to show values for low and high elevation in the plot below


# Plot
x <- rep(seq(0,1, length.out = 100), 100) # Predictor: lc_06 (Proportion of LC type)
m <- rep(seq(0,2625, length.out = 100), 100) # Moderator: Elevation
y <- -1.1457 + 2.5595*scale(x) + -0.39841*scale(m) + 0.56589*scale((x*m))
y.trial <- 1/(1+exp(-y))
  
(new.dat <- data.frame(x, m , y.trial) %>%
               as_tibble)

# Need to show values for low and high elevation
new.dat$m_groups <- cut(new.dat$m, breaks = 2) %>% 
  factor(., labels = c("Low Elev", "High Elev"))
table(new.dat$m_groups)

# Plot the data  
ggplot(new.dat,
       aes(x = x,
           y = y.trial,
           color = m_groups)) +
  geom_point(size = .9,
             alpha = .3) +
  geom_smooth(method = "lm") + # could change to loess
  theme_bw() +
  scale_color_brewer(type = "qual", 
                     palette = 3) +
  labs(x = "Independent variable", # Change the label to the independent variable being shown
       y = "Probability of Occupancy",
       color = "Moderator")
