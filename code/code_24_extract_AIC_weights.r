## ----load_libs-----------------------------------------------------------------------------
# to load data
library(readxl)

# to handle data
library(dplyr)
library(readr)
library(forcats)
library(tidyr)
library(purrr)
library(stringr)
library(magrittr)

# to wrangle models
source("code/fun_model_estimate_collection.r")
source("code/fun_make_resp_data.r")

# plotting
library(ggplot2)
library(patchwork)
source('code/fun_plot_interaction.r')

# list of species
species <- read.csv("C:\\Users\\vr235\\Desktop\\Occupancy Runs\\output\\finalizing-list-spp\\05_list-spp-spThin-min50-excl-waterBirds.csv")
list_of_species <- as.character(species$scientific_name)

# read model_imp
file_read <- "C:\\Users\\vr235\\Desktop\\Occupancy Runs\\output\\occu-10km\\occuCovs\\modelImp\\lc-clim-imp.xlsx"

model_imp <-  map2(file_read, list_of_species, function(fr, sn){
  readxl::read_excel(fr, sheet = sn)})

## ----read_model_importance-----------------------------------------------------------------
# which file to read model importance from
hypothesis_data <- mutate(hypothesis_data,
                          file_read = glue::glue('data/results/Results_{scale}/occuCovs/modelImp/{hypothesis}_imp.xlsx'))

# read in data as list column
model_data <- mutate(hypothesis_data,
                     
                     }))

# rename model data components and separate predictors
names <- c("predictor", "AICweight")

# get data for plotting: separate the interaction terms and make the response df
model_data <- mutate(model_data, 
                     model_imp = map(model_imp, function(df){
  colnames(df) <- names
  df <- separate_interaction_terms(df)
  return(df)
}))

# get aic data
# pass function over the data to get cumulative aic weight
aic_data<- map(model_imp, function(df){
    group_by(df, predictor) %>% 
      summarise(cumulative_AIC_weight = sum(as.numeric(AICweight))) %>%
      ungroup() %>% 
      
      # remove .y from predictor names
      mutate_if(is.character, .funs = function(x){
        str_remove(x, pattern = ".y")
        })})

## Need to create final figures, but getting an error
  
fig_cum_AIC <- 
  ggplot(aic_data, 
         aes(x = predictor, y = cumulative_AIC_weight, 
             colour=predictor)) +   geom_point(size=3)+
  facet_wrap(~scale, scales = "free") + 
  theme_bw()+labs(x = "Predictor", colour = "Predictor")+
  theme(legend.position = "none") +
  theme(axis.text.x = element_text(angle = 90))

# save plot
ggsave(fig_cum_AIC, filename = "figs/fig_cum_AIC.png",
       dpi = 300)


