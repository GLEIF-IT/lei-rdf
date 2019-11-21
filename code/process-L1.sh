#!/bin/bash

# Unzips and transforms $1.xml.zip to create RDF version

echo Applying L1 transformation to $1.xml.zip
echo Unzipping
unzip -o $1.xml.zip

echo Applying GLEIF-L1.xsl to $1.xml to produce $1.rdf
java -cp ~/saxon/saxon9ee.jar net.sf.saxon.Transform -s:$1.xml -xsl:GLEIF-L1.xsl -o:$1.rdf
  
echo L1 transformation complete
