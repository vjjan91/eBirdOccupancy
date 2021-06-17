#!/bin/bash
cd ..

# # make R scripts from Rmd into the R folder
# Rscript --slave -e 'lapply(list.files(pattern = "(\\d{2}_)"), function(x) knitr::purl(x, output = sprintf("R/%s", gsub(".{4}$", ".R", x)), documentation = 2))'
# 
# # make python script
# jupyter nbconvert --to python *.ipynb
# mv *.py scripts/

# convert ipython notebook to Rmd
Rscript --slave -e 'rmarkdown:::convert_ipynb("04_distance-roads-neighbours.ipynb")'

# remove top four lines of new Rmd
Rscript --slave - e 'writeLines(readLines("04_distance-roads-neighbours.Rmd")[-c(1:4)], "04_distance-roads-neighbours.Rmd")'

# style rmd
Rscript --slave -e 'styler::style_dir(".",filetype = "Rmd")'

# render books
Rscript --slave -e 'bookdown::render_book("index.Rmd")'
Rscript --slave -e 'bookdown::render_book("index.Rmd", "bookdown::pdf_document2")'

# remove script made from ipython
rm 04_distance-roads-neighbours.Rmd
