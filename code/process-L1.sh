#!/bin/bash

set -o errexit

# Unzips and transforms $1.xml.zip to create RDF version

echo Applying L1 transformation to $1.xml.zip
echo Unzipping
unzip -o $1.xml.zip

echo Applying GLEIF-L1.xsl to $1.xml to produce $1.rdf
java -Xmx512M -cp ~/saxon/saxon9ee.jar net.sf.saxon.Transform -s:$1.xml -xsl:GLEIF-L1.xsl -o:$1.rdf 2>L1-xsl.log

cat $1.rdf | ~/jena/bin/riot -q --syntax=RDFXML --stream=TURTLE > $1.ttl

echo L1 transformation complete
