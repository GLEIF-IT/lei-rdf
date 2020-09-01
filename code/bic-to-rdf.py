#!/opt/python3/bin/python3
import sys
import csv
from rdflib import Graph, Literal
from rdflib.namespace import Namespace, RDF, XSD

# Copyright (c) Data.world, 2019
# Author Pete Rivett
# Licensed under MIT License

# Converts the official LEI to BIC mapping to RDF

# Assumes input has following columns:
# BIC, LEI


# Makes use of rdflib
# - install using pip3 install rdflib
# - documentation at https://rdflib.readthedocs.io/en/stable/
# - source at https://github.com/RDFLib/rdflib/

# CLI takes name of input CSV file and outputs an RDF file which will be overwritten
if len(sys.argv) != 3:
    print("Provide name of input CSV file and output RDF file which will be overwritten")
    sys.exit()

inputfile = sys.argv[1]
outputfile = sys.argv[2]

BASE = Namespace("https://www.gleif.org/ontology/Base/")
DCT = Namespace("http://purl.org/dc/terms/")
OWL = Namespace("http://www.w3.org/2002/07/owl#")
BICDATA = Namespace("https://rdf.gleif.org/BIC/")
L1DATA = Namespace("https://rdf.gleif.org/L1/")


with open(inputfile, 'rt', encoding='utf8') as f:
    g = Graph().parse(source='BICSkeleton.ttl', format='turtle')
    dateFromName = inputfile.partition('full_')[2].partition('.csv')[0]
    ont = BICDATA['']
    g.add( (ont, DCT.issued, Literal(dateFromName+ "T00:00:00Z", datatype=XSD.dateTime)) )
    g.add( (ont, OWL.versionIRI, BICDATA['v'+dateFromName+'/']) )
    reader = csv.reader(f)
    for r, row in enumerate(reader):
        if r != 0:
            bic = row[0]
            lei = row[1]
            
            this = BICDATA['BID-'+bic]

            g.add( (this, RDF.type, BASE.RegistryIdentifier) )
            g.add( (this, BASE.tag, Literal(bic)) )
            g.add( (this, BASE.identifies, L1DATA['L-'+lei]) )
            g.add( (this, BASE.isRegisteredIn, BICDATA.BICregistry) )

  
    g.serialize(destination=outputfile, format='turtle')
