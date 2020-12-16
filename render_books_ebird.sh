#!/bin/bash
Rscript --slave -e 'bookdown::render_book("index.Rmd")'
Rscript --slave -e 'bookdown::render_book("index.Rmd", "bookdown::pdf_document2")'
