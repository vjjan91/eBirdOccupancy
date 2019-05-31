# data handling procedure for WG ebird data

all scripts are in the main folder

## reading and filtering all states data

1. run `code_06_preDataObsExpertise.r`
	a. reads in hills shapefile for bounding box
	b. reads in full raw data from N states
	c. subsets by hills bounding box (1.4 M points)
	d. wrties subset to file as `data/eBirdDataWG.csv`
	e. reads in top rows of raw sampling data
	f. gets sampling cols
	g. writes distinct sampling cols of WG data to file

**to be extended**
