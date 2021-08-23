# Source code for _Using citizen science to parse climatic and landcover influences on bird occupancy within a tropical biodiversity hotspot_

<!-- badges: start -->
  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4393647.svg)](https://doi.org/10.5281/zenodo.4393647)
<!-- badges: end -->

This repository contains code and analysis for a manuscript that uses citizen science data to parse the role of climate and land cover on avian occupancy across the Western Ghats.

## [Readable version](https://pratikunterwegs.github.io/hillybirds/)

A readable version of this analysis is available in bookdown format by clicking on the heading above.

We describe what each script of this repository is intended to achieve below.

- _01_prep-ebird-data.Rmd:_. Processing citizen science data from eBird for a given list of species across the Nilgiri and the Anamalai hills. 

- _02_prep-environmental-predictors.Rmd:_. Processing climatic and landscape predictors across our study area for occupancy modeling. The shell script `bash/get_chelsa.sh` is used to get selected CHELSA rasters, which are listed in `data/chelsa/envidatS3paths.txt`. These are used to calculate the layers BIOCLIM 4a and 15, for temperature and precipitation seasonality. A landcover layer is reclassified to 7 classes; all layers are resampled to 1km resolution.

- _03_observer-expertise.Rmd:_. Calculating observer expertise scores (later used to assign a Checklist Calibration Index) across all unique observers within our study area for the time-period 2013 to 2020.  

- _04_distance-roads-neighbours.ipynb_: This Python code in a Jupyter notebook is used to determine how far each checklist location is from the nearest road, and how far each site is from its nearest neighbour. We used Python to take advantage of `scipy` cKDtrees for spatial computation.

- 05_spatial-sampling-bias-distRoads.Rmd_: Visualising spatial clustering in checklists, in relation to roads and to other checklists.

- _06_temporal-sampling.Rmd_: Visualising temporal clustering in checklists.

- _07_final-covar-data.Rmd_: A final covariate dataframe consisting of detection level covariates and occupancy level covariates are extracted in this script.  

- _08_occupancy-models.Rmd_: Running occupancy models across climatic and landscape covariates. In addition, we run goodness-of-fit tests in this script. Species-specific probabilities of occupancy as a function of environmental predictors can be obtained from Section 10 of the Supplementary Material.  

- _09_results-AICweights-probOfOccupancy.Rmd_: Visualising the cumulative AIC weights and the magnitude and direction of species-specific probability of occupancy.  

Methods and format are derived from [Strimas-Mackey et al.](https://cornelllabofornithology.github.io/ebird-best-practices/), the supplement to [Johnston et al. (2019)](https://www.biorxiv.org/content/10.1101/574392v1).

## Attribution

Please contact the following in case of interest in the project.

[Vijay Ramesh (lead author)](https://evolecol.weebly.com/)  
PhD student, Columbia University

[Pratik Gupte (repo maintainer)](https://github.com/pratikunterwegs)  
PhD student, University of Groningen  
