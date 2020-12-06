#### Making coefficient plots for different species from occupancy models #### 
### Useful link: https://gist.github.com/dsparks/4332698

library(openxlsx)
library(dplyr)
library(tidyverse)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)
library(gridExtra)

# Load the individual model estimates 
modEstSheets <- getSheetNames("data/results/lc-clim-modelEst.xlsx")
modEst <-lapply(modEstSheets,openxlsx::read.xlsx, xlsxFile = "data/results/lc-clim-modelEst.xlsx")
names(modEst) <- modEstSheets

# Store the results in a list for plotting
model <- list()

# Making all plots
for(i in 1:length(modEst)){
    names(modEst[[i]]) <- c("Predictor","Coefficient" ,"SE" ,"lowerCI" , "upperCI" ,"z_value"  ,"Pr_z")
    plot <-  modEst[[i]] %>% filter(Pr_z<0.05)
    plot <- plot %>%
      filter(str_detect(Predictor,'psi')) %>%
      filter(!str_detect(Predictor,'Int')) %>%
      mutate(Predictor = recode(Predictor, 'psi(bio_12.y)' = 'Mean Annual Precipitation', 
                                'psi(bio_1.y)' = 'Mean Annual Temperature',
                                'psi(lc_01.y)' = 'Proportion of Agriculture',
                                'psi(lc_02.y)' = 'Proportion of Forests',
                                'psi(lc_04.y)' = 'Proportion of Plantations',
                                'psi(lc_05.y)' = 'Proportion of Settlements',
                                'psi(lc_06.y)' = 'Proportion of Tea',
                                'psi(lc_07.y)' = 'Proportion of Water Bodies'
      ))
    
    if(dim(plot)[1]==0){
      next
    } else {
    model[[i]] <- data.frame(Predictor = plot$Predictor,
                        Coefficient = plot$Coefficient,
                        SE = plot$SE,
                        lowerCI = plot$lowerCI,
                        upperCI = plot$upperCI,
                        Species = names(modEst)[i])
    
    names(model)[i] <- names(modEst)[i]
    }
}

# Plot should be outside the loop
allModelFrame <- rbindlist(model)

fig_coefPlot <- ggplot(allModelFrame) +
  geom_hline(yintercept = 0, colour = gray(1/2), lty = 2) +
  geom_linerange(aes(x = Predictor, ymin = lowerCI,ymax = upperCI),
                 lwd = 1, position = position_dodge(width = 1/2)) +
  geom_pointrange(aes(x = Predictor, y = Coefficient, ymin = lowerCI,ymax = upperCI),
                  lwd = 1/2, position = position_dodge(width = 1/2),
                  shape = 21, fill = "WHITE") + coord_flip() +
  facet_wrap(~Species,scales="free_y") +
  theme_bw() +
  theme(legend.position = "right",
        strip.text = element_text(face = "italic"),
        axis.title = element_blank())

ggsave(fig_coefPlot, filename = "figs/fig_coefPlot.png",height = 17,
       width = 25, device = png(), dpi = 300); dev.off()

# Make coefPlots for main text (include only endemic species of birds) = 12 species of birds

# Load list of endemic species
species <- read_csv("data/endemic_species_list.csv")
list_of_species <- as.character(species$scientific_name)

# Load the individual model estimates 
modEst <-lapply(list_of_species,openxlsx::read.xlsx, xlsxFile = "data/results/lc-clim-modelEst.xlsx")
names(modEst) <- list_of_species

# Store the results in a list for plotting
model <- list()

# Making all plots
for(i in 1:length(modEst)){
  names(modEst[[i]]) <- c("Predictor","Coefficient" ,"SE" ,"lowerCI" , "upperCI" ,"z_value"  ,"Pr_z")
  plot <-  modEst[[i]] %>% filter(Pr_z<0.05) 
  plot <- plot %>%
    filter(str_detect(Predictor,'psi')) %>%
    filter(!str_detect(Predictor,'Int')) %>%
    mutate(Predictor = recode(Predictor, 'psi(bio_12.y)' = 'Mean Annual Precipitation', 
                              'psi(bio_1.y)' = 'Mean Annual Temperature',
                              'psi(lc_01.y)' = 'Proportion of Agriculture',
                              'psi(lc_02.y)' = 'Proportion of Forests',
                              'psi(lc_04.y)' = 'Proportion of Plantations',
                              'psi(lc_05.y)' = 'Proportion of Settlements',
                              'psi(lc_06.y)' = 'Proportion of Tea',
                              'psi(lc_07.y)' = 'Proportion of Water Bodies'
                            ))
  if(dim(plot)[1]==0){
    next
  } else {
    model[[i]] <- data.frame(Predictor = plot$Predictor,
                             Coefficient = plot$Coefficient,
                             SE = plot$SE,
                             lowerCI = plot$lowerCI,
                             upperCI = plot$upperCI,
                             Species = names(modEst)[i])
    
    names(model)[i] <- names(modEst)[i]
  }
}

# Plot should be outside the loop
allModelFrame <- rbindlist(model)

fig_coefPlot_endemics <- ggplot(allModelFrame) +
  geom_hline(yintercept = 0, colour = gray(1/2), lty = 2) +
  geom_linerange(aes(x = Predictor, ymin = lowerCI,ymax = upperCI),
                 lwd = 1, position = position_dodge(width = 1/2)) +
  geom_pointrange(aes(x = Predictor, y = Coefficient, ymin = lowerCI,ymax = upperCI),
                  lwd = 1/2, position = position_dodge(width = 1/2),
                  shape = 21, fill = "WHITE") + coord_flip() +
  facet_wrap(~Species,scales="free_y") +
  theme_bw() +
  theme(legend.position = "right",
        strip.text = element_text(face = "italic"),
        axis.title = element_blank())

ggsave(fig_coefPlot_endemics, filename = "figs/fig_coefPlot_endemics.svg",height = 12,
       width = 17, device = svg(), dpi = 300); dev.off()





