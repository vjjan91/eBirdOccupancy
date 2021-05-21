#!/bin/bash
# code to get chelsa files
cd  data/chelsa
wget --no-host-directories --force-directories --input-file=envidatS3paths.txt
cd ../..
