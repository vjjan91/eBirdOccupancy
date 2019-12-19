#### code to identify common species ####

# extends from code_06_preDataObsExpertise.r
# uses the output dataForUse.csv

# load libs
library(data.table)

# load data
data <- fread("data/dataForUse.csv")

# get unique species
spList <- data[,.N,by=scientific_name]
setorder(spList, -N)

spList[,rank:=1:nrow(spList)]

# write to file
fwrite(spList, file = "data/dataSpeciesCount.csv")

# ends here
