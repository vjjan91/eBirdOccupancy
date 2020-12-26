# Source code for _Using citizen science to parse climatic and landcover influences on bird occupancy within a tropical biodiversity hotspot_

This repository contains code and analysis for a manuscript that uses citizen science data to parse the role of climate and land cover on avian occupancy across the Western Ghats.

## [Readable version](https://pratikunterwegs.github.io/eBirdOccupancy/)

A readable version of this analysis is available in bookdown format by clicking on the heading above.

We describe what each script of this repository is intended to achieve below.

- _01_prep-ebird-data.Rmd:_. We process citizen science data from eBird for a given list of species (the final list of species chosen for this study was processed in Section 2 of the Supplementary Material) across the Nilgiri and the Anamalai hills. 

- _02_prep-environmental-predictors.Rmd:_. We process climatic and landscape predictors across our study area for occupancy modeling (Section 3 and Section 4 of the Supplementary Material outlines how we obtained a high resolution land cover classification used in the above script as well as analyzing spatial autocorrelation among climatic predictors).  

- _03_observer-expertise.Rmd:_. We calculate observer expertise scores (Checklist Calibration Index) across all unique observers within our study area for the time-period 2013 to 2019. Please refer to Section 7 of the Supplementary Material to visualize how Number of species reported varies as a function of observer expertise scores.  

- _03_spatial-sampling-bias-distRoads.Rmd:_. This script analyzes how far each checklist location is from the nearest road, and how far each site is from its nearest neighbour.  

- _04_final-covar-data.Rmd:_. A final covariate dataframe consisting of detection level covariates and occupancy level covariates are extracted in this script. Prior to obtaining the final dataframe, we considered unique localities for each species that were atleast 1km apart from one another to account for spatial independence (see Section 8 of the Supplementary Material) and tested a number of spatial thinning approaches (see Section 9 of the Supplementary Material).  

- _05_occupancy-models.Rmd:_. This script models occupancy across climatic and landscape covariates. In addition, we run goodness-of-fit tests in this script. Species-specific probabilities of occupancy as a function of environmental predictors can be obtained from Section 10 of the Supplementary Material.  

- _06_results-AICweights-probOfOccupancy.Rmd:_. This script analyzes visualizes the cumulative AIC weights and the magnitude and direction of species-specific probability of occupancy.  

The manuscript's supplementary material can be found at https://github.com/pratikunterwegs/ebird-wghats-supplement  

Methods and format are derived from [Strimas-Mackey et al.](https://cornelllabofornithology.github.io/ebird-best-practices/), the supplement to [Johnston et al. (2019)](https://www.biorxiv.org/content/10.1101/574392v1).

## Attribution

Please contact the following in case of interest in the project.

[Vijay Ramesh (lead author)](https://evolecol.weebly.com/)  
PhD student, Columbia University

[Pratik Gupte (repo maintainer)](https://github.com/pratikunterwegs)  
PhD student, University of Groningen  