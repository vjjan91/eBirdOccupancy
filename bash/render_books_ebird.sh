#!/bin/bash
cd ..

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

# rename pdf to pdf with date
mv docs/ebird_occupancy_main_text.pdf docs/supplementary_material_ebird_occupancy_`date -I`.pdf
