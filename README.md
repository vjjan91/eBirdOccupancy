# Source code for _Using citizen science to parse climatic and landcover influences on bird occupancy within a tropical biodiversity hotspot_

<!-- badges: start -->
  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/168210226.svg)](https://zenodo.org/badge/latestdoi/168210226)
  
<!-- badges: end -->

This repository contains code and analysis for a manuscript that uses citizen science data to parse the role of climate and land cover on avian occupancy across the Western Ghats. 

To view the associated manuscript (now accepted at _Ecography_), please use the following DOI:

## [Readable version](https://vjjan91.github.io/eBirdOccupancy/)

A readable version of this analysis is available in bookdown format by clicking on the heading above.

We describe what each script of this repository is intended to achieve below.

- _01_selecting-ebird-data.Rmd:_. In this script, we pre-processing citizen science data from [eBird](https://ebird.org/home) and finalized a list of species for downstream processeing (this list can be modified based on the requirements you have for your study). For this study, we manually removed raptors _Accipitriformes_ and _Falconidae_, swifts _Apodiformes_, and swallows _Hirundinidae_, since the observations of these birds are generally made when they are in flight and can be prone to errors. We considered only terrestrial birds and removed species that are often easily confused for their congeners (eg. green/greenish warbler). This resulted in a total of 1.29 million observations (presences) between 2013 to 2021 across 79 terrestrial, diurnal birds found in our study area (list of species can be found in the data folder).

- _02_prep-ebird-data.Rmd:_. In this script, we processing the eBird data by applying a number of filters for running occupancy models. Apart from adding spatial filters, we added a sampling effort based filter following *Johnston et al. 2019*, wherein we considered only those checklists with duration in minutes less than 300 and distance in kilometers traveled is less than 5km. Lastly, we excluded those group checklists where the number of observers was greater than 10. For the sake of occupancy modeling of appropriate detection and occupancy covariates, we restricted all our checklists between December 1st and May 31st (non-rainy months)and checklists recorded between 5am and 7pm.

- _03_prep-environmental-predictors.Rmd:_. Here, we processed climatic and landscape predictors across our study area for occupancy modeling. The shell script `bash/get_chelsa.sh` is used to get selected CHELSA rasters, which are listed in `data/chelsa/envidatS3paths.txt`. These were used to calculate the layers BIOCLIM 4a and 15a, for temperature seasonality and precipitation seasonality, respectively. A land cover layer was reclassified to 7 classes; all layers were then resampled to 1km resolution.

- _04_checklist-calibration-index.Rmd:_. We calculated observer-specific expertise scores (later used to assign a Checklist Calibration Index) across all unique observers within our study area for the time-period 2013 to 2021.  

- _05_distance-roads-neighbours.ipynb_: This script is used to determine how far each checklist location is from the nearest road, and how far each site is from its nearest neighbour. We used Python to take advantage of `scipy` cKDtrees for spatial computation.

- _06_spatial-sampling-bias-distRoads.Rmd_: Here, we visualized spatial clustering in checklists, in relation to roads and to other checklists.

- _07_temporal-sampling.Rmd_: Here, we visualized temporal clustering in checklists.

- _08_final-covar-data.Rmd_: In this script, we prepared a final covariate dataframe consisting of detection level covariates and occupancy level covariates.

- _09_occupancy-models.Rmd_: Here, we run occupancy models across climatic and landscape covariates. In addition, we run goodness-of-fit tests in this script.   

- _10_visualize-occu-predictor-effects.Rmd_: We visualized the magnitude and direction of species-specific probabilities of occupancy.  

- _11_predict-probOfOccupancy.Rmd_: We plot species-specific probabilities of occupancy as a function of significant environmental predictors and mapped occupancy across the study area for a given list of species and significant predictors.  

Methods and format are derived from [Strimas-Mackey et al.](https://cornelllabofornithology.github.io/ebird-best-practices/), the supplement to [Johnston et al. 2021)](https://onlinelibrary.wiley.com/doi/pdf/10.1111/ddi.13271).

## Attribution

Please contact the following in case of interest in the project. 

[Vijay Ramesh (lead author)](https://evolecol.weebly.com/)  
PhD student, Columbia University

[Pratik Gupte (repo maintainer)](https://github.com/pratikunterwegs)  
PhD student, University of Groningen  
