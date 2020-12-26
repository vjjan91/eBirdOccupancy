#!/bin/bash

# render books
Rscript --slave -e 'bookdown::render_book("index.Rmd")'
Rscript --slave -e 'bookdown::render_book("index.Rmd", "bookdown::pdf_document2")'

# make R scripts from Rmd into the R folder
Rscript --slave -e 'lapply(list.files(pattern = "(\\d{2}_)"), function(x) knitr::purl(x, output = sprintf("R/%s", gsub(".{4}$", ".R", x)), documentation = 2))'

# style Rmd files
# make R scripts from Rmd into the R folder
Rscript --slave -e 'styler::styler(style_dir("R/")'
Rscript --slave -e 'styler::styler(style_dir(".")'
