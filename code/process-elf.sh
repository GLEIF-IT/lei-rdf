#!/bin/bash

set -o errexit

# Param 1 is the full filename with no extension
# e.g. 2019-07-19_elf-code-list-publication-version-1.1
# Param 2 is the dataset on data.world including username e.g. rivettp/gleif-2019-10-31
# Requires shell variable DATAWORLD_TOKEN for registered user API token

echo Processing ELF file $1 to dataset $2

echo Converting to $1.ttl
python3 elf-to-rdf.py $1.csv $1.ttl

# Upload to GLEIF
# TBD

# Upload to data.world 
echo uploading $1.ttl to data.world $2/files/EntityLegalFormData.ttl

curl -H "Authorization: Bearer $DATAWORLD_TOKEN" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @$1.ttl \
  https://api.data.world/v0/uploads/$2/files/EntityLegalFormData.ttl
  
echo ELF processing complete
