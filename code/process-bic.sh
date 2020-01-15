#!/bin/bash
# Param 1 is the filename of the dated mapping  
# e.g. bic_lei_gleif_v1_monthly_full_20191025
# Param 2 is the dataset on data.world including username e.g. rivettp/gleif-2019-10-31
# Requires shell variable DATAWORLD_TOKEN for registered user API token

set -o errexit

echo Processing BIC file $1 to dataset $2
echo Fetching file $1 from GLEIF site
curl -O https://www.gleif.org/content/4-lei-data/7-lei-mapping/1-download-bic-to-lei-relationship-files/$1.csv

echo Converting to $1.ttl
python3 bic-to-rdf.py $1.csv $1.ttl

# Upload to GLEIF
# TBD

# Upload to data.world 
echo uploading $1.ttl to data.world $2/files/BICData.ttl

curl -H "Authorization: Bearer $DATAWORLD_TOKEN" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @$1.ttl \
  https://api.data.world/v0/uploads/$2/files/BICData.ttl
  
echo BIC processing complete
