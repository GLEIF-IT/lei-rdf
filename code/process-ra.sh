#!/bin/bash
# Param is the full filename with no extension
# e.g. 2018-12-12_ra-list_v1.4
# Param 2 is the dataset on data.world including username e.g. rivettp/gleif-2019-10-31
# Requires shell variable DATAWORLD_TOKEN for registered user API token

echo Processing RA file $1 to dataset $2
echo Fetching file $1 from GLEIF site
curl -O https://www.gleif.org/content/2-about-lei/7-code-lists/1-gleif-registration-authorities-list/$1.csv

echo Converting to $1.ttl
python3 ra-to-rdf.py $1.csv $1.ttl

# Upload to GLEIF
# TBD

# Upload to data.world
echo uploading $1.ttl to data.world $2/files/RegistrationAuthorityData.ttl

curl -H "Authorization: Bearer $DATAWORLD_TOKEN" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @$1.ttl \
  https://api.data.world/v0/uploads/$2/files/RegistrationAuthorityData.ttl
  
echo RA processing complete
