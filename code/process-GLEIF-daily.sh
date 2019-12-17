#!/bin/bash
# Processes daily GLEIF files and uploads to data.world as a single zip
# param 1 is the dataset 

# Requires shell variable DATAWORLD_TOKEN for registered user API token

set -o errexit -o nounset -o pipefail

echo Decrypting secrets
python3 decrypt-secrets.py

echo Processing GLEIF files to dataset $1

leidata=$(curl https://leidata-preview.gleif.org/api/v2/golden-copies/publishes)

L1Path=$(echo $leidata | jq '.data[0].lei2.full_file.xml.url' | tr -d "\"")
L2Path=$(echo $leidata | jq '.data[0].rr.full_file.xml.url' | tr -d "\"")
RepExPath=$(echo $leidata | jq '.data[0].repex.full_file.xml.url' | tr -d "\"")

pattern="s;https://leidata-preview.gleif.org/storage/golden-copy-files/\(.*\).xml.zip;\1;"

L1=$(echo $L1Path | sed "$pattern")
L2=$(echo $L2Path | sed "$pattern")
RepEx=$(echo $RepExPath | sed "$pattern")

### L1
echo L1 processing
echo Fetching file $L1 from GLEIF site
curl -O $L1Path

local1=${L1##*/}

./process-L1.sh $local1

# Upload to GLEIF
# zip $local1.zip $local1.rdf 
# FTP $local1.rdf to GLEIF

# rename to predictable name
mv $local1.rdf L1Data.rdf

### L2
echo L2 processing
echo Fetching file $L2 from GLEIF site
curl -O $L2Path

local2=${L2##*/}

./process-L2.sh $local2

# Upload to GLEIF
# zip $local2.zip $local2.rdf 
# FTP $local2.rdf to GLEIF

# rename to predictable name
mv $local2.rdf L2Data.rdf

### RepEx
echo RepEx processing
echo Fetching file $RepEx from GLEIF site
curl -O $RepExPath

localr=${RepEx##*/}

./process-RepEx.sh $localr

# Upload to GLEIF
# zip $localr.zip $localr.rdf 
# FTP $localr.rdf to GLEIF

# rename to predictable name
mv $localr.rdf RepExData.rdf

# Combine all files
echo zipping 3 files
zip upload.zip L1Data.rdf L2Data.rdf RepExData.rdf

# Upload to GLEIF
echo uploading to data.world dataset $1
curl -H "Authorization: Bearer $DATAWORLD_TOKEN" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @L2Data.rdf.zip \
  https://api.data.world/v0/uploads/$1/files/upload.zip

echo daily processing complete
