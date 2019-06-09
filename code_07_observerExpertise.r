#### code to explore observer expertise ####

# load libs and data
library(data.table)

ebdNspChk <- fread("data/eBirdChecklistSpecies.csv", nrows = 1e3)

# remove NAs
ebdNspChk <- na.omit(ebdNspChk)

# choosing covariates from Kelling et al. 2015
# covariates reflect different classes of peredictors
# 1. variability in the species richness (time of year and habitat)
# 2. variability in species habits (time of day and effort)
# 3. observer effect (obsever id)

# fit a poisson GLM per Johnston et al. 2018
library(lme4)

modNspecies <- glmer(N ~ sqrt(samplingEffort) + julianDate + I(julianDate^2) + julianDate + I(julianDate^2) + (1|observer/checklist_id), data = ebdNspChk, family = poisson)

