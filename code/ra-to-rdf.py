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
# Tested with 2019-12-05 1.5 version which now has comments in column 9
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
DCT = Namespace("http://purl.org/dc/terms/")
OWL = Namespace("http://www.w3.org/2002/07/owl#")
RA = Namespace("https://www.gleif.org/ontology/RegistrationAuthority/")
RADATA = Namespace("https://rdf.gleif.org/RegistrationAuthority/")
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
    elif regionName == 'Bonaire':
        code = 'BQ-BO' # To distinguish from the special territory of the same name
    elif regionName == 'Alderney':
        code = 'GG-1012-Territory' # Alderney Island, has no ISO code
    elif regionName == 'Mato Grosso du Sul':
        code = 'BR-MS' # Mato Grosso do Sul
    elif regionName == 'Abu Dhabi':
        code = 'AE-AZ' # Abū Z̧aby
    elif regionName == 'Sharjah':
        code = 'AE-SH' # Ash Shāriqah
    elif regionName == 'Ajman':
        code = 'AE-AJ' # ‘Ajmān
    elif regionName == 'Dubai':
        code = 'AE-DU' # Dubayy
    elif regionName == 'Ras Al Khaimah':
        code = 'AE-RK' # Ra’s al Khaymah
    elif regionName == 'Ras Al Khamaih':
        code = 'AE-RK' # Ra’s al Khaymah
    elif regionName == 'Fujairah':
        code = 'AE-FU' # Al Fujayrah
    elif regionName == 'Umm al-Quwain':
        code = 'AE-UQ' # Umm al Qaywayn
    elif regionName == 'Santiago':
        code = 'CL-RM' # Region Metropolita de Santiago
    elif regionName == 'San Andrés Islas':
        code = 'CO-SAP' # San Andrés, Providencia y Santa Catalina
    elif regionName == 'Bavaria':
        code = 'DE-BY' # Bayern 
    elif regionName == 'Hesse':
        code = 'DE-HE' # Hessen 
    elif regionName == 'Mecklenburg-Western Pomerania':
        code = 'DE-MV' # Mecklenburg-Vorpommern 
    elif regionName == 'North Rhine-Westphalia':
        code = 'DE-NW' # Nordrhein-Westfalen 
    elif regionName == 'Rhineland-Palatinate':
        code = 'DE-RP' # Rheinland-Pfalz 
    elif regionName == 'Thuringia':
        code = 'DE-TH' # Thuringen 
    elif regionName == 'Catalonia':
        code = 'ES-CT' # Catalunya
    elif regionName == 'Amman':
        code = 'JO-AM' # Al 'A simah
    elif regionName == 'Labuan':
        code = 'MY-15' # Wilayah Persekutuan Labuan 
    else:
        return ''
    return LCC2[code]


with open(inputfile, 'rt', encoding='utf8') as f:
    g = Graph().parse(source='RegistrationAuthoritySkeleton.ttl', format='turtle')
    # Use the filename for metadata since it's not in the file itself
    dateFromName = inputfile.partition('_')[0] + "T00:00:00Z"
    vsnFromName = inputfile.partition('ra-list-v')[2].partition('.csv')[0]
    ont = RADATA['']
    g.add( (ont, DCT.issued, Literal(dateFromName, datatype=XSD.dateTime)) )
    g.add( (ont, OWL.versionIRI, RADATA['v'+vsnFromName+'/']) )
    cgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes/', format='xml')
    lgraph = Graph().parse(location='https://www.omg.org/spec/LCC/Languages/ISO639-1-LanguageCodes/', format='xml')
    reader = csv.reader(f)
    # need to normalize spaces since the CSV files has some oddities. Pattern is to use join.split
    for r, row in enumerate(reader):
        if r != 0:
            id = row[0]
            countryName = " ".join(row[1].split())
            countryCode = " ".join(row[2].split())
            jurisdictionName = " ".join(row[3].split())
            registrarNameInternat = " ".join(row[4].split())
            registrarNameLocal = " ".join(row[5].split())
            orgNameInternat = " ".join(row[6].split())
            orgNameLocal = " ".join(row[7].split())
            website = " ".join(row[8].split())
            comments = " ".join(row[9].split())
            
            this = RADATA[id]
            org = RADATA[id + '-ORG']
           
            g.add( (this, RDF.type, RA.BusinessRegistry) )
            g.add( (this, RDF.type, RA.RegistrationAuthorityCode) )
            g.add( (this, BASE.tag, Literal(id)) )
            g.add( (this, BASE.identifies, this) )

            # look up the local language
            countryIdentifier = cgraph.value(predicate=LCCLR.hasTag, object=Literal(countryCode, datatype=XSD.string))
            country = cgraph.value(subject=countryIdentifier, predicate=LCCLR.identifies)
            # in theory there could be more than one language
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
                g.add( (this, BASE.hasWebsite, Literal(str(website).strip(), datatype=XSD.anyURI)) )

            if comments != '':
                g.add( (this, RDFS.comment, Literal(comments)) )

            if jurisdictionName == countryName:
                g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )
            else:
                # Apply exceptions where RA name does not match the official name in LCC (incl as comment)
                regionOverride = regionException(jurisdictionName)
                if regionOverride != '':
                    g.add( (this, BASE.hasCoverageArea, regionOverride) )
                else:    
                    # Remote lookup
                    c = Graph().parse(location='https://www.omg.org/spec/LCC/Countries/Regions/ISO3166-2-SubdivisionCodes-'+countryCode+'/', format='xml')
                    regions = list(c.subjects(RDFS.label, Literal(jurisdictionName, ralang)))
                    if len(regions) == 1:
                        # get the code for it
                        region = regions[0]
                        identifier = c.value(predicate=LCCLR.identifies, object=region)
                        tag = c.value(subject=identifier, predicate=LCCLR.hasTag)
                        g.add( (this, BASE.hasCoverageArea, LCC2[tag]) )
                    elif len(regions) == 0:
                        print('In country: ', countryCode, ' could not find region: ', jurisdictionName + '@' + ralang)
                        g.add( (this, BASE.hasCoverageArea, LCC1[countryCode]) )
                        g.add( (this, RDFS.comment, Literal('Jurisdiction, which could not be mapped to an official region: ' + jurisdictionName+ '@' + ralang)) )
                    else:
                        print('In country: ', countryCode, ' found more than one match for region: ', jurisdictionName + '@' + ralang, ': ')
                        for i, reg in enumerate(regions):
                            print('    ', reg, '|')
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
