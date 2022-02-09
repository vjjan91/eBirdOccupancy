# Source code for _Using citizen science to parse climatic and landcover influences on bird occupancy within a tropical biodiversity hotspot_

<!-- badges: start -->
  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4393647.svg)](https://doi.org/10.5281/zenodo.4393647)
<!-- badges: end -->

This repository contains code and analysis for a manuscript that uses citizen science data to parse the role of climate and land cover on avian occupancy across the Western Ghats.

## [Readable version](https://vjjan91.github.io/eBirdOccupancy/)

A readable version of this analysis is available in bookdown format by clicking on the heading above.

We describe what each script of this repository is intended to achieve below.

- _01_selecting-ebird-data.Rmd:_.Pre-processing of citizen science data from eBird and finalizing a list of species for our study. We ensured that we manually removed raptors _Accipitriformes_ and _Falconidae_, swifts _Apodiformes_, and swallows _Hirundinidae_, since the observations of these birds are generally made when they are in flight and can be prone to errors. We considered only terrestrial birds and removed species that are often easily confused for their congeners (eg. green/greenish warbler). This resulted in a total of 1.29 million observations (presences) across 79 terrestrial, diurnal birds found in our study area (list of species can be found in Appendix S1)

- _02_prep-ebird-data.Rmd:_. Processing eBird data by applying a number of filters and preparing it to run occupancy models. Apart from adding spatial filters, we added a sampling effort based filter following [@johnston2019a], wherein we considered only those checklists with duration in minutes is less than 300 and distance in kilometres traveled is less than 5km. Lastly, we excluded those group checklists where the number of observers was greater than 10. For the sake of occupancy modeling of appropriate detection and occupancy covariates, we restrict all our checklists between December 1st and May 31st (non-rainy months)and checklists recorded between 5am and 7pm.

- _03_prep-environmental-predictors.Rmd:_. Processing climatic and landscape predictors across our study area for occupancy modeling. The shell script `bash/get_chelsa.sh` is used to get selected CHELSA rasters, which are listed in `data/chelsa/envidatS3paths.txt`. These are used to calculate the layers BIOCLIM 1 and 12, for mean annual temperature and annual precipitation respectively. A landcover layer is reclassified to 7 classes; all layers are resampled to 1km resolution.

- _04_checklist-calibration-index.Rmd:_. Calculating observer-specific expertise scores (later used to assign a Checklist Calibration Index) across all unique observers within our study area for the time-period 2013 to 2021.  

- _05_distance-roads-neighbours.ipynb_: This Python code in a Jupyter notebook is used to determine how far each checklist location is from the nearest road, and how far each site is from its nearest neighbour. We used Python to take advantage of `scipy` cKDtrees for spatial computation.

- _06_spatial-sampling-bias-distRoads.Rmd_: Visualizing spatial clustering in checklists, in relation to roads and to other checklists.

- _07_temporal-sampling.Rmd_: Visualizing temporal clustering in checklists.

- _08_final-covar-data.Rmd_: A final covariate dataframe consisting of detection level covariates and occupancy level covariates are extracted in this script.  

- _09_occupancy-models.Rmd_: Running occupancy models across climatic and landscape covariates. In addition, we run goodness-of-fit tests in this script.   

- _10_visualize-occu-predictor-effects.Rmd_: Visualizing the magnitude and direction of species-specific probability of occupancy.  

- _11_predict-probOfOccupancy.Rmd_: Plotting species-specific probabilities of occupancy as a function of significant environmental predictors and mapping occupancy across the study area for a given list of species and significant predictors.  

Methods and format are derived from [Strimas-Mackey et al.](https://cornelllabofornithology.github.io/ebird-best-practices/), the supplement to [Johnston et al. (2019)](https://www.biorxiv.org/content/10.1101/574392v1).

## Attribution

Please contact the following in case of interest in the project.

[Vijay Ramesh (lead author)](https://evolecol.weebly.com/)  
PhD student, Columbia University

[Pratik Gupte (repo maintainer)](https://github.com/pratikunterwegs)  
PhD student, University of Groningen  
