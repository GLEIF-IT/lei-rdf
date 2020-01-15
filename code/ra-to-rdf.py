#!/opt/python3/bin/python3
import sys
import csv
import re
from rdflib import Graph, Literal
from rdflib.namespace import Namespace, RDF, XSD, RDFS

# Copyright (c) Data.world, 2019
# Author Pete Rivett
# Licensed under MIT License

# Converts the official Registration Authority list CSV file to RDF
# Tested with 2018-12-12 version
# Requires internet access to OMG site for the LCC ontology for country and language data

# Assumes input has following columns:
# Registration Authority Code, Country, Country Code, Jurisdiction (country or region), 
# International name of Register, Local name of Register, 
# International name of organisation responsible for the Register, Local name of organisation responsible for the Register,
# Website, Date IP disclaimer included, 
# Comments, End Date


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
RA = Namespace("https://www.gleif.org/ontology/RegistrationAuthority/")
RADATA = Namespace("https://www.gleif.org/ontology/RegistrationAuthorityData/")
LCCLR = Namespace("https://www.omg.org/spec/LCC/Languages/LanguageRepresentation/")
LCCCR = Namespace("https://www.omg.org/spec/LCC/Countries/CountryRepresentation/")
LCC1 = Namespace("https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/")
LCC2 = Namespace("https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/")

def langTag(langName):
    if langName.lower() == 'french':
        return 'fr'
    elif langName.lower() == 'german':
        return 'ge'
    elif langName.lower() == 'italian':
        return 'it'
    else:
        return 'en'

def regionException(regionName):
    if regionName == 'Republic of Srpska':
        code = 'BA-SRP' # Republika Srpska
    elif regionName == 'Mato Grosso du Sul':
        code = 'BR-MS' # Mato Grosso do Sul
    elif regionName == 'Amman':
        code = 'JO-AM' # Al 'A simah
    elif regionName == 'Abu Dhabi':
        code = 'AE-AZ' # Abu Z.aby
    elif regionName == 'Sharjah':
        code = 'AE-SH' # Ash Shariqah
    elif regionName == 'Ajman':
        code = 'AE-AJ' # 'Ajman
    elif regionName == 'Dubai':
        code = 'AE-DU' # Abu Dubayy
    elif regionName == 'Ras al-Khamaih':
        code = 'AE-RK' # Ra’s al Khaymah
    elif regionName == 'Fujairah':
        code = 'AE-FU' # Al Fujayrah
    elif regionName == 'Umm al-Quwain':
        code = 'AE-UQ' # Umm al Qaywayn
    elif regionName == 'Labuan':
        code = 'MY-15' # Wilayah Persekutuan Labuan 
    elif regionName == 'Santiago':
        code = 'CL-RM' # Region Metropolita de Santiago
    elif regionName == 'Fujairah':
        code = 'AE-FU' # Al Fujayrah
    else:
        return ''
    return LCC2[code]


with open(inputfile, 'rt', encoding='utf8') as f:
    g = Graph().parse(source='RegistrationAuthoritySkeleton.ttl', format='turtle')
    cgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes/', format='xml')
    lgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Languages/ISO639-1-LanguageCodes/', format='xml')
    reader = csv.reader(f)
    for r, row in enumerate(reader):
        if r != 0:
            id = row[0]
            countryName = row[1]
            countryCode = row[2]
            jurisdictionName = row[3]
            registrarNameInternat = row[4]
            registrarNameLocal = row[5]
            orgNameInternat = row[6]
            orgNameLocal = row[7]
            website = row[8]
            # skip disclaimer date
            comments = row[10]
            # skip (due to no values) endDate = row[11]
            
            this = RADATA[id]
            org = RADATA[id + '-ORG']
           
            g.add( (this, RDF.type, RA.BusinessRegistry) )
            g.add( (this, RDF.type, RA.RegistrationAuthorityCode) )
            g.add( (this, BASE.tag, Literal(id)) )
            g.add( (this, BASE.identifies, this) )

            # look up the local language
            countryIdentifier = cgraph.value(predicate=LCCLR.hasTag, object=Literal(countryCode, datatype=XSD.string))
            country = cgraph.value(subject=countryIdentifier, predicate=LCCLR.identifies)
            language = cgraph.value(subject=country, predicate=LCCCR.usesAdministrativeLanguage)
            langId = lgraph.value(predicate=LCCLR.identifies, object=language)
            ralang = lgraph.value(subject=langId, predicate=LCCLR.hasTag)

            if registrarNameInternat != '':
                g.add( (this, BASE.hasNameTranslatedEnglish, Literal(registrarNameInternat)) )
            if registrarNameLocal != '':
                locals = re.findall("in ([a-z]+): (.+?)(;|$)", registrarNameLocal, re.IGNORECASE)
                # locals = re.findall("in ([a-z]+): (.+?)(;|$)", "In French: Registre IDE; in German: UID-Register; in Italian: Registro IDI",re.IGNORECASE)
                if len(locals) == 0:
                    g.add( (this, BASE.hasNameLocal, Literal(registrarNameLocal, lang=ralang)) )
                else:
                    for i, local in enumerate(locals):
                        lang = langTag(local[0])
                        if i == 0:
                            g.add( (this, BASE.hasNameLocal, Literal(local[1], lang=lang)) )
                        else:
                            g.add( (this, BASE.hasNameAdditionalLocal, Literal(local[1], lang=lang)) )

            if orgNameInternat != '' or orgNameLocal != '':
                g.add( (this, BASE.isManagedBy, org) )
                
            if website != '':
                g.add( (this, BASE.hasWebsite, Literal(website, datatype=XSD.anyURI)) )

            if comments != '':
                g.add( (this, RDFS.comment, Literal(comments)) )

            if jurisdictionName == countryName:
                g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )
            else:
                # Apply exceptions where RA name does not match the official name in LCC
                regionOverride = regionException(jurisdictionName)
                if regionOverride != '':
                    g.add( (this, BASE.hasCoverageArea, regionOverride) )
                else:    
                    # Remote lookup
                    c = Graph().parse(location='https://www.omg.org/spec/LCC/Countries/Regions/ISO3166-2-SubdivisionCodes-'+countryCode+'/', format='xml')
                    regions = list(c.subjects(RDFS.label, Literal(jurisdictionName)))
                    if len(regions) == 1:
                        # get the code for it
                        region = regions[0]
                        identifier = c.value(predicate=LCCLR.identifies, object=region)
                        tag = c.value(subject=identifier, predicate=LCCLR.hasTag)
                        g.add( (this, BASE.hasCoverageArea, LCC2[tag]) )
                    elif len(regions) == 0:
                        print('In country: ', countryCode, ' could not find region: ', jurisdictionName)
                        g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )
                        g.add( (this, RDFS.comment, Literal('Jurisdiction, which could not be mapped to an official region: ' + jurisdictionName)) )
                    else:
                        print('In country: ', countryCode, ' found more than one match for region: ', jurisdictionName)
                        g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )

            if orgNameInternat != '' or orgNameLocal !='':
                g.add( (org, RDF.type, RA.RegistrationAuthority) )
                if orgNameInternat != '':
                    g.add( (org, BASE.hasNameTranslatedEnglish, Literal(orgNameInternat)) )
                if orgNameLocal != '':
                    locals = re.findall("in ([a-z]+): (.+?)(;|$)", orgNameLocal, re.IGNORECASE)
                    if len(locals) == 0:
                         g.add( (org, BASE.hasNameLocal, Literal(orgNameLocal, lang=ralang)) )
                    else:
                        for i, local in enumerate(locals):
                            lang = langTag(local[0])
                            if i == 0:
                                g.add( (org, BASE.hasNameLocal, Literal(local[1], lang=lang)) )
                            else:
                                g.add( (org, BASE.hasNameAdditionalLocal, Literal(local[1], lang=lang)) )


    g.serialize(destination=outputfile, format='turtle')
