#!/bin/bash
# Processes daily GLEIF files and uploads to data.world as a single zip
# param 1 is the dataset 

# Requires shell variable DATAWORLD_TOKEN for registered user API token

set -o errexit

pip3 install -r requirements.txt

if [ -f decrypt-secrets.py ]; then
	echo Decrypting secrets
	`python3 decrypt-secrets.py`
fi

echo Processing GLEIF files to dataset $1

# Get URIs for latest files
echo Getting URIs for latest Golden Copy files from GLEIF

curl https://leidata-preview.gleif.org/api/v2/golden-copies/publishes >latest.json

# Extract the latest URI for L1, L2, Repex
#  jq -r '.data[0]|{lei:.lei2.full_file.xml.url, rr:.rr.full_file.xml.url, repex:.repex.full_file.xml.url}'
shopt -s lastpipe
cat latest.json | jq -r '.data[0]|.lei2.full_file.xml.url' | read L1
#2019/10/31/254175/20191031-1600-gleif-goldencopy-lei2-golden-copy
cat latest.json | jq -r '.data[0]|.rr.full_file.xml.url' | read L2
#20191031-1600-gleif-goldencopy-rr-golden-copy
cat latest.json | jq -r '.data[0]|.repex.full_file.xml.url' | read RepEx

### L1
echo L1 processing
echo Fetching file $L1 from GLEIF site
curl -C- -O $L1

LL1=${L1##*/}
local1=${LL1%.xml.zip}

./process-L1.sh $local1

# Upload to GLEIF
# zip $local1.zip $local1.rdf
# FTP $local1.rdf to GLEIF

export JVM_ARGS="-Xmx512M"

# rename to predictable name
mv $local1.rdf L1Data.rdf
riot --output=TTL L1Data.rdf > L1Data.ttl


### L2
echo L2 processing
echo Fetching file $L2 from GLEIF site
curl -O $L2

LL2=${L2##*/}
local2=${LL2%.xml.zip}

./process-L2.sh $local2

# Upload to GLEIF
# zip $local2.zip $local2.rdf
# FTP $local2.rdf to GLEIF

# rename to predictable name
mv $local2.rdf L2Data.rdf
riot  --output=TTL L2Data.rdf > L2Data.ttl

### RepEx
echo RepEx processing
echo Fetching file $RepEx from GLEIF site
curl -O $RepEx

LRepEx=${RepEx##*/}
localr=${LRepEx%.xml.zip}

./process-RepEx.sh $localr

# Upload to GLEIF
# zip $localr.zip $localr.rdf
# FTP $localr.rdf to GLEIF

# rename to predictable name
mv $localr.rdf RepExData.rdf
riot --output=TTL RepExData.rdf > RepExData.ttl

# Combine all files
echo zipping 3 files
zip upload.zip L1Data.ttl L2Data.ttl RepExData.ttl

# Upload to data.world
echo uploading to data.world dataset $1
curl -H "Authorization: Bearer $DATAWORLD_TOKEN" \
  -X POST -H "Content-Type: multipart/form-data" \
  --form file='@upload.zip' \
  https://api.data.world/v0/uploads/$1/files?expandArchives=true

echo Getting URI for latest Registration Authorities List
`python3 latest-ra.py`

RRA1=${RA##*/}
RRA1=${RRA1%.csv}

echo Fetching file $RRA1 from GLEIF site
curl -C- -O $RA

./process-ra.sh $RRA1 $1

echo Getting URI for latest Entity Legal Forms
`python3 latest-elf.py`

ELF1=${ELF##*/}
ELF1=${ELF1%.csv}

echo Fetching file $ELF1 from GLEIF site
curl -C- -O $ELF

./process-elf.sh $ELF1 $1

echo Getting URI for latest Business Identifier Codes
`python3 latest-bic.py`

BIC1=${BIC##*/}
BIC1=${BIC1%.csv}

echo Fetching file $BIC1 from GLEIF site
curl -C- -O $BIC

./process-bic.sh $BIC1 $1

echo processing complete
