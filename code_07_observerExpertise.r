#### code to explore observer expertise ####

# load libs and data
library(data.table)

nSpecObs <- fread("data/eBirdChecklistSpecies.csv")

# check observers with more than 10 records
nSpecObs[,.N,observer][N >= 10, .N]

# how does one choose covariates for observer expertise?