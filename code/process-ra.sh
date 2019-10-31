#!/bin/bash
# Param is the full filename with no extension
# e.g. 2018-12-12_ra-list_v1.4

curl -O https://www.gleif.org/content/2-about-lei/7-code-lists/1-gleif-registration-authorities-list/$1.csv
python3 ra-to-rdf.py $1.csv $1.ttl
# FTP $1.rdf to GLEIF

# Upload to GLEIF
# Uses rivettp's API token
token="eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJwcm9kLXVzZXItY2xpZW50OnJpdmV0dHAiLCJpc3MiOiJhZ2VudDpyaXZldHRwOjo3NWZmODA5OS1lYzI2LTQzYTktYjk4Zi1lNTRhYjM5ZTM2MTkiLCJpYXQiOjE1MDcyNDEwMzAsInJvbGUiOlsidXNlcl9hcGlfcmVhZCIsInVzZXJfYXBpX3dyaXRlIl0sImdlbmVyYWwtcHVycG9zZSI6dHJ1ZSwic2FtbCI6e319.ioambjK--OqAGzVJM82qYyxLFSHCW4KYqs1SNQV-g2bRdFUURaMZl4RBq3nGMIorufxdb0XcVHrnJCq3YEIg4A"

curl -H "Authorization: Bearer $token" \
  -X PUT -H "Content-Type: application/octet-stream" \
  --data-binary @$1.ttl \
  https://api.data.world/v0/uploads/rivettp/gleif-2019-10-31/files/RegistrationAuthorityData.ttl
  

