# Source code for _Using citizen science to parse climatic and landcover influences on bird occupancy within a tropical biodiversity hotspot_

<!-- badges: start -->
  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/168210226.svg)](https://zenodo.org/badge/latestdoi/168210226)
  
<!-- badges: end -->

This repository contains code and analysis for a manuscript that uses citizen science data to parse the role of climate and land cover on avian occupancy across the Western Ghats. 

To view the associated manuscript (now accepted at _Ecography_), please use the following DOI:

## [Readable version](https://vjjan91.github.io/eBirdOccupancy/)

A readable version of this analysis is available in bookdown format by clicking on the heading above.

## Source code for the analyses

We describe what each script (`.Rmd`) of this repository is intended to achieve below.

- _01_selecting-ebird-data.Rmd:_. In this script, we pre-processing citizen science data from [eBird](https://ebird.org/home) and finalized a list of species for downstream processing (this list can be modified based on the requirements you have for your study). For our study, we manually removed raptors _Accipitriformes_ and _Falconidae_, swifts _Apodiformes_, and swallows _Hirundinidae_, since the observations of these birds are generally made when they are in flight and can be prone to errors. We considered only terrestrial birds and largely passerine species, and removed many species that are often easily confused for their congeners (eg. green/greenish warbler). Our filtering process resulted in a total of 1.29 million observations (presences) between 2013 to 2021 across 79 terrestrial, diurnal birds found in our study area (list of species can be found in the `data/` folder).

- _02_prep-ebird-data.Rmd:_. In this script, we processed the [eBird](https://ebird.org/home) by applying a number of filters. These filters included spatial, sampling, and temporal filters. For example, we added a sampling effort based filter following (Johnston et al. 2019), wherein we considered only those checklists with duration in minutes less than 300 and distance in kilometers traveled is less than 5km. We excluded those group checklists where the number of observers was greater than 10. For the sake of occupancy modeling of appropriate detection and occupancy covariates, we restricted all our checklists between December 1st and May 31st (non-rainy months)and checklists recorded between 5am and 7pm (Please vary this step based on your question, study area and list of species).

- _03_prep-environmental-predictors.Rmd:_. Here, we processed climatic and landscape predictors across our study area. The shell script `bash/get_chelsa.sh` is used to get selected CHELSA rasters, which are listed in `data/chelsa/envidatS3paths.txt`. These were used to calculate the layers BIOCLIM 4a and 15a, for temperature seasonality and precipitation seasonality, respectively. A land cover layer was reclassified to 7 classes; all layers were then resampled to 1km resolution.

- _04_checklist-calibration-index.Rmd:_. Differences in local avifaunal expertise among citizen scientists can lead to biased species detection when compared with data collected by a consistent set of trained observers (Van Strien et al. 2013). Including observer expertise as a detection covariate in occupancy models using eBird data can help account for this variation (Johnston et al. 2018). We calculated observer-specific expertise scores (later used to assign a Checklist Calibration Index) across all unique observers within our study area for the time-period 2013 to 2021. 

- _05_distance-roads-neighbours.ipynb_: This Python script is used to determine how far each checklist location is from the nearest road, and how far each site is from its nearest neighbour. We used Python to take advantage of `scipy` cKDtrees for spatial computation.   

- _06_spatial-sampling-bias-distRoads.Rmd_: Here, we visualized spatial clustering in checklists, in relation to roads and to other checklists.

- _07_temporal-sampling.Rmd_: Here, we visualized temporal clustering in checklists.

- _08_final-covar-data.Rmd_: In this script, we prepared a final covariate dataframe consisting of detection level covariates and occupancy level covariates.

- _09_occupancy-models.Rmd_: Here, we run occupancy models across climatic and landscape covariates. In addition, we run goodness-of-fit tests.     

- _10_visualize-occu-predictor-effects.Rmd_: We visualized the magnitude and direction of species-specific probabilities of occupancy.  

- _11_predict-probOfOccupancy.Rmd_: We plot species-specific probabilities of occupancy as a function of significant environmental predictors and mapped occupancy across the study area for a given list of species and significant predictors.  

Methods and format are derived from [Strimas-Mackey et al.](https://cornelllabofornithology.github.io/ebird-best-practices/), the supplement to [Johnston et al. 2021)](https://onlinelibrary.wiley.com/doi/pdf/10.1111/ddi.13271).

## Data 

The `data/` folder contains the following datasets required to reproduce the above scripts.  

### eBird data

Please download the eBird sampling and EBD dataset from https://ebird.org/home prior to running the above code. 

### Species specific data

- `species_list.csv`: Contains a list of species that was analyzed in this study.  

- `species-trait-dat.csv`: Contains selected columns of species trait data which was downloaded from Sheard et al. (2020).   

### Climate data

All climate is housed in the `chelsa/` folder within `data/`. In this folder, you will find processed `.tif` files corresponding to temperature seasonality (bio4a) and precipitation seasonality (bio15).  

### Spatial data

All spatial data is house in two folders `spatial/` and `landUseClassification/` within the `data/` folder. The `spatial/` folder contains shapefiles corresponding to the outline of our study area (the Nilgiris and the Anamalai hills), an Open Street Map Roads shapefile and an elevation raster (obtained from SRTM). The `landUseClassification/` folder contains a raster of land cover classes (source: Roy et al. 2015) and a `.csv` corresponding to a reclassification matrix.   

## Results

This folder contains outputs that were obtained by running the above scripts. The number that prefixes each script corresponds to the source code scripts. For example, `01` would correspond to _01_selecting-ebird-data.Rmd:_ and so on.  

- `01_nchk-per-grid.csv`: Number of eBird checklists recorded in each 25 x 25 km grid across the study area.  

- `01_ngrids-per-spp.csv`: Number of 25 x 25 km grids that a species was recorded in.  

- `01_prop-grids-per-spp.csv`: Proportion of grids in which a species was recorded in.  

- `01_list-of-species-cutoff.csv`: List of species that occur in at least 5% of checklists across a minimum of 50% of the grids they have been reported in. This file also contains a count of checklists for each species (between 2013 and 2021).  

- `02_data_prelim_processing.Rdata`: An R object that saves a pre-processed dataframe of observations following spatial, temporal, and sampling filters.  

- `04_data-nspp-per-chk.csv`: Number of species per checklist.  

- `04_data-covars-perChklist.csv`: Land cover, julian data and a few other detection covariates are included in a dataframe for each checklist observation.  

- `04_model-output-expertise.txt`: The output of a generalized linear mixed model are housed in this `.txt` file which can be found in the `modOutput\` folder.  

- `04_data-obsExpertise-score.csv`: A dataframe containing observer-specific expertise scores.  

- `06_distance-roads-sites.csv`: Distance to roads from sampling sites are described here. Location-specific distance to roads can be found in `06_locs_dist_to_road.csv`.  

- `08_data-class-balance.csv`: Results from spatial thinning.  

- `08_data-covars-2.5km.csv`: A final covariate dataframe for occupancy modeling.  

- `09_scaled-covars-2.5km.csv`: The above dataframe, following scaling of detection and occupancy covariates. 

- `09_lc-clim.csv`: List of all combinations of models.  

- `09_lc-clim-avg.csv`: Model-averaged coefficients for the full and subset models.  
- `09_lc-clim-imp.csv`: Results from _MuMIn::importance()_.  

- `09_lc-clim-modelEst.csv`: A table of model-averaged coefficients, standard error, upper and lower CI.  

- `09_goodness-of-fit-2.5km.csv`: Results of chi-square goodness-of-fit tests.  

- `10_cumulative-AIC-weights.csv`: Calculation of cumulative AIC weights for climate and land cover predictors.  

- `10_data-occupancy-predictors.csv`: List of species and corresponding environmental covariates that they are significantly associated with.  

- `10_data-predictor-effect.csv`: List of species and the model-averaged coefficients of corresponding environmental covariates that they are significantly associated with.  

- `10_data-predictor-direction-nSpecies.csv`: Magnitude and direction of association with environmental covariates.  

- `10_results-predictors-species-traits.csv` A dataframe that contains outputs from occupancy models merged with species trait data.  

## Figures

The `figs\` folder contains figures accompanying the main text (see publication in _Ecography_), as well as supplementary material figures. The main text figures are suffixed with numbers (example:`fig01`).   

## Appendix

The `appendix\` folder contains supplementary files that are provided with the published manuscript and have been described earlier.    

## Attribution

Please contact the following in case of interest in the project. 

[Vijay Ramesh (lead author)](https://evolecol.weebly.com/)  
PhD student, Columbia University

[Pratik Gupte (repo maintainer)](https://github.com/pratikunterwegs)  
PhD student, University of Groningen  
