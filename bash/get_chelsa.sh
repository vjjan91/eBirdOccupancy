#!/bin/bash
cd ..
# code to get chelsa files
wget -P data/chelsa/ --no-host-directories --force-directories --input-file=../data/chelsa/envidatS3paths.txt
