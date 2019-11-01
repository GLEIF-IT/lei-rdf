#!/bin/bash
# Param is the full filename with no extension
# e.g. 2019/10/31/254175/20191031-1600-gleif-goldencopy-lei2-golden-copy

curl -O https://leidata-preview.gleif.org/storage/golden-copy-files/$1.xml.zip

local=${1##*/}

unzip -o $local.xml.zip

echo applying GLEIF-L1.xsl to $local.xml
java -cp ~/saxon/saxon9ee.jar net.sf.saxon.Transform -s:$local.xml -xsl:GLEIF-L1.xsl -o:$local.rdf

zip $local.rdf.zip $local.rdf 

# FTP $1.rdf to GLEIF

# rename to upload to predicatble name
mv $local.rdf L1Data.rdf
zip L1Data.rdf.zip L1Data.rdf

# Upload to GLEIF
# Uses rivettp's API token
token="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJwcm9kLXVzZXItY2xpZW50OnJpdmV0dHAiLCJpc3MiOiJhZ2VudDpyaXZldHRwOjo3NWZmODA5OS1lYzI2LTQzYTktYjk4Zi1lNTRhYjM5ZTM2MTkiLCJpYXQiOjE1MDcyNDEwMzAsInJvbGUiOlsidXNlcl9hcGlfcmVhZCIsInVzZXJfYXBpX3dyaXRlIl0sImdlbmVyYWwtcHVycG9zZSI6dHJ1ZSwic2FtbCI6e319.ioambjK--OqAGzVJM82qYyxLFSHCW4KYqs1SNQV-g2bRdFUURaMZl4RBq3nGMIorufxdb0XcVHrnJCq3YEIg4A"

echo uploading to data.world 
curl -H "Authorization: Bearer $token" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @L1Data.rdf.zip \
  https://api.data.world/v0/uploads/rivettp/gleif-2019-10-31/files/L1Data.rdf.zip
  
echo complete

