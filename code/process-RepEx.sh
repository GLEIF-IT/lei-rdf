#!/bin/bash
# Unzips and transforms $1.xml.zip to create RDF version

echo Applying RepEx transformation to $1.xml.zip
echo Unzipping
unzip -o $1.xml.zip

echo Applying GLEIF-RepEx.xsl to $1.xml to produce $1.rdf
java -cp ~/saxon/saxon9ee.jar net.sf.saxon.Transform -s:$1.xml -xsl:GLEIF-RepEx.xsl -o:$1.rdf
  
echo RepEx transformation complete

