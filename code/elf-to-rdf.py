#!/opt/python3/bin/python3
import sys
import csv
import re
from rdflib import Graph, Literal
from rdflib.namespace import Namespace, RDF, XSD

# Copyright (c) Data.world, 2019-2020
# Author Pete Rivett
# Licensed under MIT License

# Converts the official Entity Legal Form list CSV file to RDF
# Tested with 2020-11-19 version
# There could be many entries for the same code, each with a different language
# Assumes input has following columns:
# ELF Code, Country of formation, Country Code (ISO 3166-1, Jurisdiction of formation, Country sub-division code (ISO 3166-2),
# Entity Legal Form name Local name, Language, Language Code (ISO 639-1),
# Entity Legal Form name Transliterated name (per ISO 01-140-10),
# Abbreviations Local language, Abbreviations transliterated,
# Date created YYYY-MM-DD (ISO 8601), ELF Status ACTV/INAC,
# Modification, Modification date YYYY-MM-DD (ISO 8601), Reason


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
ELF = Namespace("https://www.gleif.org/ontology/EntityLegalForm/")
ELFDATA = Namespace("https://rdf.gleif.org/EntityLegalForm/")
LCCLR = Namespace("https://www.omg.org/spec/LCC/Languages/LanguageRepresentation/")
LCCCR = Namespace("https://www.omg.org/spec/LCC/Countries/CountryRepresentation/")
LCC1 = Namespace("https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/")
LCC2 = Namespace("https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/")


with open(inputfile, 'rt', encoding='utf8') as f:
    g = Graph().parse(source='EntityLegalFormSkeleton.ttl', format='turtle')
    # Use the filename for metadata since it's not in the file itself
    dateFromName = inputfile.partition('_')[0] + "T00:00:00Z"
    vsnFromName = inputfile.partition('list_')[2].partition('.csv')[0]
    ont = ELFDATA['']
    g.add( (ont, DCT.issued, Literal(dateFromName, datatype=XSD.dateTime)) )
    g.add( (ont, OWL.versionIRI, ELFDATA[vsnFromName+'/']) )
    cgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes/', format='xml')
    lgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Languages/ISO639-1-LanguageCodes/', format='xml')
    reader = csv.reader(f)
    for r, row in enumerate(reader):
        id = row[0]
        # need to normalize spaces since the CSV files has some oddities. Pattern is to use join.split
        if r != 0 and id != '8888' and id != '9999':
            countryName = " ".join(row[1].split())
            countryCode = " ".join(row[2].split())
            jurisdictionName = " ".join(row[3].split())
            jurisdictionCode = " ".join(row[4].split())          
            elfNameLocal = " ".join(row[5].split())
            # elfNameLang = row[6]
            elfNameLangCode = " ".join(row[7].split())
            elfNameInternat = " ".join(row[8].split())
            abbrevLocal = " ".join(row[9].split())
            abbrevInternat = " ".join(row[10].split())
            # skip  date = row[11]
            status = " ".join(row[12].split())
            # skip modifications
            
            this = ELFDATA['ELF-'+id]

            g.add( (this, RDF.type, ELF.EntityLegalForm) )
            g.add( (this, RDF.type, ELF.EntityLegalFormIdentifier) )
            g.add( (this, BASE.tag, Literal(id)) )
            g.add( (this, BASE.identifies, this) )

            if elfNameInternat != '':
                g.add( (this, BASE.hasNameTransliterated, Literal(elfNameInternat, lang=elfNameLangCode)) )
            if elfNameLocal != '':
                g.add( (this, BASE.hasNameLocal, Literal(elfNameLocal, lang=elfNameLangCode)) )

            if jurisdictionCode != '':
                g.add( (this, BASE.hasCoverageArea, LCC2[jurisdictionCode]) )
            elif countryCode != '':
                g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )
        
            if abbrevLocal != '':
                abbrevs = re.findall("([\w/\-\.,]+)(;|$)", abbrevLocal)
                for abbrev in abbrevs:
                    g.add( (this, BASE.hasAbbreviationLocal, Literal(abbrev[0], lang=elfNameLangCode)) )

            if abbrevInternat != '':
                abbrevs = re.findall("([\w/\-\.,]+)(;|$)", abbrevInternat)
                for abbrev in abbrevs:
                    g.add( (this, BASE.hasAbbreviationTransliterated, Literal(abbrev[0], lang=elfNameLangCode)) )

            if status == 'INAC':
                    g.add( (this, OWL.deprecated, Literal(True, datatype=XSD.boolean)) )
 
    g.serialize(destination=outputfile, format='turtle')
