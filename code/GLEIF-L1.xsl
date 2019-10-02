<?xml version="1.0"?>
<!DOCTYPE stylesheet [
  <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
  <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
  <!ENTITY dct "http://purl.org/dc/terms/" >
  <!ENTITY lcc-3166-1-adj "https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/">
  <!ENTITY lcc-3166-2-adj "https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCode-Adjunct/">
  
]>

<xsl:stylesheet  version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:owl="http://www.w3.org/2002/07/owl#"
  xmlns:skos="http://www.w3.org/2004/02/skos/core#" 
  xmlns:dct="http://purl.org/dc/terms/"
  xmlns:gleif="http://www.gleif.org/concatenated-file/header-extension/2.0" 
  xmlns:lei="http://www.gleif.org/data/schema/leidata/2016"
  xmlns:gleif-ELF-data="https://www.gleif.org/ontology/EntityLegalFormData/"
  xmlns:gleif-L1="https://www.gleif.org/ontology/L1/"
  xmlns:gleif-L1-data="https://www.gleif.org/ontology/L1Data/"
  xmlns:gleif-RA-data="https://www.gleif.org/ontology/RegistrationAuthorityData/"
  xmlns:gleif-base="https://www.gleif.org/ontology/Base/"
  xmlns:lcc-3166-1-adj="https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/"
  xmlns:lcc-3166-2-adj="https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/"
  xmlns:saxon="http://saxon.sf.net/"
  
  extension-element-prefixes="gleif lei saxon">
  
  <!--#########################################################################-->
  <!-- Converts LEI CDF format Level 1 version 2.1 data to RDF-->
  <!-- Uses XSLT 3.0 streaming for large data manipulation -->
  <!-- 
  -->
  
  <!--#########################################################################-->
  
  <xsl:output method="xml" indent="yes" media-type="application/xml" 
    doctype-public="rdf:RDF" /> 
  <xsl:strip-space elements="*"/>
  
  
  <xsl:param name="issued-date" select="'2019-01-11T08:46:48Z'"/>
  
  <xsl:variable name="invalid-id-chars" select="' /:,()&gt;&lt;&amp;'"/> <!-- Cannot be used in xmi ids -->
  <xsl:variable name="replacement-id-chars" select="'_..._____'"/> <!-- Substitute for above - must match in number -->
  <xsl:variable name="null-date" as="xs:dateTime">1970-01-01T00:00:00.00</xsl:variable>
  
  <!-- This is no longer needed since Stardog does not support large numbers of XML entities 
    It would be needed to allow use of XML entities such as &lcc-cr; in the output 
  For genuine use of & e.g. in names we first translate to ^ then convert back to entity in character map >
  <xsl:character-map name="ampersand">
    <xsl:output-character character="&amp;" string="&#x26;"/>
    <xsl:output-character character="^" string="&#x26;amp;"/>
  </xsl:character-map> 
  <xsl:character-map name="ltgt">
    <xsl:output-character character="&lt;" string="&#x3C;"/>
    <xsl:output-character character="&gt;" string="&#x3E;"/>
  </xsl:character-map> 
  -->

  <xsl:mode streamable="yes"/>
  
  <xsl:template match="/">
    <rdf:RDF xml:base="https://www.gleif.org/ontology/L1Data/">
      <owl:Ontology rdf:about="https://www.gleif.org/ontology/L1Data/">
        <rdfs:label>Ontology data generated from GLEIF L1 data in CDF 2.1 format</rdfs:label>
        <dct:issued rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
          <xsl:value-of select="$issued-date"/>
        </dct:issued>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/L1/"/>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/EntityLegalFormData/"/> 
        <owl:imports rdf:resource="https://www.gleif.org/ontology/RegistrationAuthorityData/"/>
        <owl:imports rdf:resource="https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/"/>
        <owl:imports rdf:resource="https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/"/>
      </owl:Ontology>
      <xsl:for-each select="lei:LEIData/lei:LEIRecords/lei:LEIRecord" saxon:threads="32">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:template>


  <xsl:template match="lei:LEIRecord">
    <!-- Keep a record of the entry then process it - to allow streaming -->
    <xsl:variable name="record" as="element()*"> <!-- Keep track of anything interesting -->
      <xsl:copy-of select="."/>
    </xsl:variable>
    <xsl:variable name="lei" select="$record/lei:LEI"/>
    <!-- Primary addresses - avoid duplication -->
    <xsl:apply-templates select="$record/lei:Entity/lei:LegalAddress" mode="rec">
      <xsl:with-param name="lei" select="$lei"/>
    </xsl:apply-templates>
    <xsl:if test="not($record/lei:Entity/lei:HeadquartersAddress/lei:FirstAddressLine = $record/lei:Entity/lei:LegalAddress/lei:FirstAddressLine)">
      <xsl:apply-templates select="$record/lei:Entity/lei:HeadquartersAddress" mode="rec">
        <xsl:with-param name="lei" select="$lei"/>
      </xsl:apply-templates>
    </xsl:if>
    <!-- Other addresses - avoid duplication -->    
    <xsl:apply-templates select="$record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_LEGAL_ADDRESS']" mode="rec">
      <xsl:with-param name="lei" select="$lei"/>
    </xsl:apply-templates>
    <xsl:if test="not($record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_HEADQUARTERS_ADDRESS']/lei:FirstAddressLine = 
      $record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_LEGAL_ADDRESS']/lei:FirstAddressLine)">
      <xsl:apply-templates select="$record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type,'ALTERNATIVE_LANGUAGE_HEADQUARTERS_ADDRESS']" mode="rec">
        <xsl:with-param name="lei" select="$lei"/>
      </xsl:apply-templates>
    </xsl:if>
    <!-- Transliterated addresses - avoid duplication -->    
    <xsl:apply-templates select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[contains(@type,'ASCII_TRANSLITERATED_LEGAL_ADDRESS')]" mode="rec">
      <xsl:with-param name="lei" select="$lei"/>
    </xsl:apply-templates>
    <xsl:if test="not($record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[contains(@type,'ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS')]/lei:FirstAddressLine = 
      $record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[contains(@type,'ASCII_TRANSLITERATED_LEGAL_ADDRESS')]/lei:FirstAddressLine)">
      <xsl:apply-templates select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[contains(@type,'ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS')]" mode="rec">
        <xsl:with-param name="lei" select="$lei"/>
      </xsl:apply-templates>
    </xsl:if>
    <!-- Registration identifiers - avoid duplication -->
    <xsl:apply-templates select="$record/lei:Entity/lei:RegistrationAuthority" mode="rec">
      <xsl:with-param name="lei" select="$lei"/>
    </xsl:apply-templates>
    <xsl:if test="not($record/lei:Registration/lei:ValidationAuthority/lei:ValidationAuthorityEntityID = $record/lei:Entity/lei:RegistrationAuthority/lei:RegistrationAuthorityEntityID)">
      <xsl:apply-templates select="$record/lei:Registration/lei:ValidationAuthority" mode="rec">
        <xsl:with-param name="lei" select="$lei"/>
      </xsl:apply-templates>
    </xsl:if>
    <!-- Assume OtherValidationAuthorities/OtherValidationAuthority are different so no need to avoid duplication optimization -->
    <xsl:apply-templates select="$record/lei:Registration/lei:OtherValidationAuthorities/lei:OtherValidationAuthority" mode="rec">
      <xsl:with-param name="lei" select="$lei"/>
    </xsl:apply-templates>
    <xsl:variable name="status" select="$record/lei:Entity/lei:EntityStatus"/>
    <xsl:variable name="category" select="$record/lei:Entity/lei:EntityCategory"/>
    <xsl:variable name="el">
      <xsl:choose>
        <xsl:when test="$category='SOLE_PROPRIETOR'">gleif-L1:SoleProprietor</xsl:when>
        <xsl:when test="$category='BRANCH'">gleif-L1:Branch</xsl:when>
        <xsl:when test="$category='FUND'">gleif-L1:Fund</xsl:when>
        <xsl:otherwise>gleif-L1:LegalEntity</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$el}">
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei)"/>
      <xsl:element name="gleif-L1:hasLegalName">
        <xsl:copy-of select="$record/lei:Entity/lei:LegalName/@xml:lang"/>
        <xsl:value-of select="$record/lei:Entity/lei:LegalName"/>
      </xsl:element>
      <xsl:for-each select="$record/lei:Entity/lei:OtherEntityNames/lei:OtherEntityName[@type='PREVIOUS_LEGAL_NAME']">
        <xsl:element name="gleif-L1:hasPreviousLegalName">
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
      <xsl:for-each select="$record/lei:Entity/lei:OtherEntityNames/lei:OtherEntityName[@type='TRADING_OR_OPERATING_NAME']">
        <xsl:element name="gleif-L1:hasTradingOrOperatingName">
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
      <xsl:for-each select="$record/lei:Entity/lei:OtherEntityNames/lei:OtherEntityName[@type='ALTERNATIVE_LANGUAGE_LEGAL_NAME']">
        <xsl:element name="gleif-L1:hasAlternativeLanguageLegalName">
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
      <xsl:for-each select="$record/lei:Entity/lei:TransliteratedOtherEntityNames/lei:TransliteratedOtherEntityName[@type='PREFERRED_ASCII_TRANSLITERATED_LEGAL_NAME']">
        <xsl:element name="gleif-L1:hasPreferredASCIITransliteratedName">
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
      <xsl:for-each select="$record/lei:Entity/lei:TransliteratedOtherEntityNames/lei:TransliteratedOtherEntityName[@type='AUTO_ASCII_TRANSLITERATED_LEGAL_NAME']">
        <xsl:element name="gleif-L1:hasAutoASCIITransliteratedName">
          <xsl:copy-of select="@xml:lang"/>
          <xsl:value-of select="."/>
        </xsl:element>
      </xsl:for-each>
      <!-- TODO Geocode -->
      <xsl:variable name="la1" select="$record/lei:Entity/lei:LegalAddress/lei:FirstAddressLine"/>
      <xsl:variable name="hq1" select="$record/lei:Entity/lei:HeadquartersAddress/lei:FirstAddressLine"/>
      <xsl:if test="$record/lei:Entity/lei:LegalAddress">
        <xsl:element name="gleif-L1:hasLegalAddress">
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAL')"/>
        </xsl:element>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$hq1 != '' and $hq1 = $la1">
          <xsl:element name="gleif-L1:hasHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAL')"/>
          </xsl:element>              
        </xsl:when>
        <xsl:when test="$hq1 != ''">
          <xsl:element name="gleif-L1:hasHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQL')"/>
          </xsl:element>
        </xsl:when>
      </xsl:choose>
      <!-- Other Addresses with Alternative Language -->
      <!-- Possible TODO allow for multiple other addresses -->
      <xsl:variable name="ala1" select="$record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_LEGAL_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:variable name="ahq1" select="$record/lei:Entity/lei:OtherAddresses/lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_HEADQUARTERS_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:if test="$ala1 != ''">
        <xsl:element name="gleif-L1:hasAlternativeLanguageLegalAddress">
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAA')"/>
        </xsl:element>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$ahq1 != '' and $ahq1 = $ala1">
          <xsl:element name="gleif-L1:hasAlternativeLanguageHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAA')"/>
          </xsl:element>              
        </xsl:when>
        <xsl:when test="$ahq1 != ''">
          <xsl:element name="gleif-L1:hasAlternativeLanguageHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQA')"/>
          </xsl:element>
        </xsl:when>
      </xsl:choose>
      <!-- Transliterated addresses -->
      <!-- Assume that the data will not have both an Auto and a Preferred for the same type of address -->
      <xsl:variable name="tlaa1" select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[@type='AUTO_ASCII_TRANSLITERATED_LEGAL_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:variable name="tlap1" select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[@type='PREFERRED_ASCII_TRANSLITERATED_LEGAL_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:variable name="thqa1" select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[@type='AUTO_ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:variable name="thqp1" select="$record/lei:Entity/lei:TransliteratedOtherAddresses/lei:TransliteratedOtherAddress[@type='PREFERRED_ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS']/lei:FirstAddressLine"/>
      <xsl:if test="$tlap1 != ''">
        <xsl:element name="gleif-L1:hasPreferredASCIITransliteratedLegalAddress">
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="$tlaa1 != ''">
        <xsl:element name="gleif-L1:hasAutoASCIITransliteratedLegalAddress">
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
        </xsl:element>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$thqp1 != '' and ($thqp1 = $tlap1 or $thqp1 = $tlaa1)">
          <xsl:element name="gleif-L1:hasPreferredASCIITransliteratedHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
          </xsl:element>              
        </xsl:when>
        <xsl:when test="$thqp1 != ''">
          <xsl:element name="gleif-L1:hasPreferredASCIITransliteratedHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQT')"/>
          </xsl:element>
        </xsl:when>
        <xsl:when test="$thqa1 != '' and ($thqa1 = $tlap1 or $thqa1 = $tlaa1)">
          <xsl:element name="gleif-L1:hasAutoASCIITransliteratedHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
          </xsl:element>              
        </xsl:when>
        <xsl:when test="$thqa1 != ''">
          <xsl:element name="gleif-L1:hasAutoASCIITranslitratedHeadquartersAddress">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQT')"/>
          </xsl:element>
        </xsl:when>
      </xsl:choose>
      <!-- Expiration -->    
      <xsl:variable name="reason" select="$record/lei:Entity/lei:EntityExpirationReason"/>
      <xsl:if test="$reason != ''">
        <gleif-base:hasEntityExpirationReason>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/Base/EntityExpirationReason</xsl:text>
            <xsl:choose>
              <xsl:when test="$reason = 'CORPORATE_ACTION'">CorporateAction</xsl:when>
              <xsl:when test="$reason = 'DISSOLVED'">Dissolved</xsl:when>
              <xsl:when test="$reason = 'OTHER'">Other</xsl:when>
              <xsl:otherwise>Other</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </gleif-base:hasEntityExpirationReason>
      </xsl:if>
      <xsl:variable name="expdate" select="$record/lei:Entity/lei:EntityExpirationDate"/>
      <xsl:if test="$expdate != ''">
        <gleif-base:hasEntityExpirationDate rdf:datatype="&xsd;dateTime">
          <xsl:value-of select="$expdate"/>
        </gleif-base:hasEntityExpirationDate>
      </xsl:if>
      <!-- Registration -->
      <xsl:variable name="bus-reg" select="$record/lei:Entity/lei:RegistrationAuthority/lei:RegistrationAuthorityID"/>
      <xsl:if test="$bus-reg != 'RA999999'">
        <xsl:variable name="bus-reg-text" select="$record/lei:Entity/lei:RegistrationAuthority/lei:OtherRegistrationAuthorityID"/>
        <xsl:variable name="bus-reg-ent-id" select="$record/lei:Entity/lei:RegistrationAuthority/lei:RegistrationAuthorityEntityID"/>
        <xsl:variable name="reg-id">
          <xsl:choose>
            <xsl:when test="$bus-reg = 'RA888888' and $bus-reg-text != ''">
              <xsl:value-of select="translate($bus-reg-text, $invalid-id-chars, $replacement-id-chars)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$bus-reg"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <gleif-L1:hasRegistrationIdentifier>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/L1Data/BID-</xsl:text>
            <xsl:value-of select="$reg-id"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="translate(string($bus-reg-ent-id), $invalid-id-chars, $replacement-id-chars)"/>
          </xsl:attribute>
        </gleif-L1:hasRegistrationIdentifier>
      </xsl:if>
      <!-- Jurisdiction -->
      <xsl:element name="gleif-base:hasLegalJurisdiction">
        <!-- ASSUMES that a) countries are also classified as Jurisdictions (which this will do) 
          and b) they have URIs corresponding to their code -->
        <xsl:variable name="jurisdiction" select="$record/lei:Entity/lei:LegalJurisdiction"/>
        <xsl:attribute name="rdf:resource">
          <xsl:choose>
            <xsl:when test="contains($jurisdiction, '-')">https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/</xsl:when>
            <xsl:otherwise>https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/</xsl:otherwise>
          </xsl:choose>
          <xsl:value-of select="$jurisdiction"/>
        </xsl:attribute>
      </xsl:element>
      <!-- Successor -->
      <xsl:variable name="succ" select="$record/lei:Entity/lei:SuccessorEntity/lei:SuccessorLEI"/>
      <xsl:if test="$succ != ''">
        <gleif-base:hasSuccessor>
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-',  $succ)"/>
        </gleif-base:hasSuccessor>
      </xsl:if>
      <xsl:variable name="succ-name" select="$record/lei:Entity/lei:SuccessorEntity/lei:SuccessorEntityName"/>
      <xsl:if test="$succ-name != ''">
        <gleif-L1:hasSuccessorName>
          <xsl:copy-of select="$succ-name/@xml:lang"/>
          <xsl:value-of select="$succ-name"/>
        </gleif-L1:hasSuccessorName> 
      </xsl:if>
      <!-- Legal form -->
      <!-- TODO check if legalFormCode is 8888 or 9999 that LegalFormText is provided, and if not log a message -->
      <xsl:variable name="legal-form-code" select="$record/lei:Entity/lei:LegalForm/lei:EntityLegalFormCode"/>
      <xsl:variable name="other-form" select="$record/lei:Entity/lei:LegalForm/lei:OtherLegalForm"/>
      <xsl:if test="$legal-form-code != '' and $legal-form-code != '8888' and $legal-form-code != '9999'">
        <xsl:element name="gleif-L1:hasLegalForm">
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/ELFData/ELF-', $legal-form-code)"/>
        </xsl:element>            
      </xsl:if>
      <xsl:if test="$other-form != ''">
        <xsl:element name="gleif-L1:hasLegalFormText">
          <xsl:copy-of select="$record/lei:Entity/lei:LegalForm/lei:OtherLegalForm/@xml:lang"/>
          <xsl:value-of select="$other-form"/>
        </xsl:element>            
      </xsl:if>
      <!-- Associated entity -->
      <xsl:if test="$category='FUND'">
        <xsl:variable name="assoc" select="$record/lei:Entity/lei:AssociatedEntity/lei:AssociatedLEI"/>
        <xsl:if test="$assoc != ''">
          <xsl:element name="gleif-L1:hasFundFamily">
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-',  $assoc)"/>
          </xsl:element>
        </xsl:if>
        <xsl:variable name="assoc-name" select="$record/lei:Entity/lei:AssociatedEntity/lei:AssociatedEntityName"/>
        <xsl:if test="$assoc-name != ''">
          <xsl:element name="gleif-L1:hasFundFamilyName">
            <xsl:copy-of select="$assoc-name/@xml:lang"/>
            <xsl:value-of select="$assoc-name"/>
          </xsl:element> 
        </xsl:if>
      </xsl:if>
      <!-- Status -->
      <xsl:element name="gleif-base:hasEntityStatus">
        <xsl:attribute name="rdf:resource">          
          <xsl:choose>
            <xsl:when test="$status = 'ACTIVE'">https://www.gleif.org/ontology/Base/EntityStatusActive</xsl:when>
            <xsl:otherwise>https://www.gleif.org/ontology/Base/EntityStatusInactive</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:element>
    </xsl:element>
        
    <gleif-L1:LegalEntityIdentifier>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LEI')"/>
      <rdf:type rdf:resource="https://www.gleif.org/ontology/L1/LegalEntityIdentifierRegistryEntry"/>
      <gleif-L1:LEI>
        <xsl:value-of select="$lei"/>
      </gleif-L1:LEI>
      <gleif-L1:identifiesAndRecords>
        <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei)"/>
      </gleif-L1:identifiesAndRecords>
      <gleif-base:hasInitialRegistrationDate rdf:datatype="&xsd;dateTime">
        <xsl:value-of select="$record/lei:Registration/lei:InitialRegistrationDate"/>
      </gleif-base:hasInitialRegistrationDate>
      <gleif-base:hasLastUpdateDate rdf:datatype="&xsd;dateTime">
        <xsl:value-of select="$record/lei:Registration/lei:LastUpdateDate"/>
      </gleif-base:hasLastUpdateDate>
      <xsl:variable name="regstat" select="$record/lei:Registration/lei:RegistrationStatus"/>
      <gleif-base:hasRegistrationStatus>
        <xsl:attribute name="rdf:resource">
          <xsl:text>https://www.gleif.org/ontology/</xsl:text>
          <xsl:choose>
            <xsl:when test="$regstat = 'ANNULLED'">L1/RegistrationStatusAnnulled</xsl:when>
            <xsl:when test="$regstat = 'CANCELLED'">L1internal/RegistrationStatusCancelled</xsl:when>
            <xsl:when test="$regstat = 'DUPLICATE'">L1/RegistrationStatusDuplicate</xsl:when>
            <xsl:when test="$regstat = 'ISSUED'">L1/RegistrationStatusIssued</xsl:when>
            <xsl:when test="$regstat = 'LAPSED'">L1/RegistrationStatusLapsed</xsl:when>
            <xsl:when test="$regstat = 'MERGED'">L1/RegistrationStatusMerged</xsl:when>
            <xsl:when test="$regstat = 'PENDING_ARCHIVAL'">L1/RegistrationStatusPendingArchival</xsl:when>
            <xsl:when test="$regstat = 'PENDING_TRANSFER'">L1/RegistrationStatusPendingTransfer</xsl:when>
            <xsl:when test="$regstat = 'PENDING_VALIDATION'">L1internal/RegistrationStatusPendingValidation</xsl:when>
            <xsl:when test="$regstat = 'RETIRED'">L1/RegistrationStatusRetired</xsl:when>
            <xsl:when test="$regstat = 'TRANSFERRED'">L1internal/RegistrationStatusTransferred</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </gleif-base:hasRegistrationStatus>
      <gleif-base:hasNextRenewalDate rdf:datatype="&xsd;dateTime">
        <xsl:value-of select="$record/lei:Registration/lei:NextRenewalDate"/>
      </gleif-base:hasNextRenewalDate>
      <gleif-L1:hasManagingLOU>
        <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $record/lei:Registration/lei:ManagingLOU)"/>
      </gleif-L1:hasManagingLOU>
      <!-- TODO cope with multiple values for validationSources (very rare) -->
      <xsl:variable name="valsource" select="$record/lei:Registration/lei:ValidationSources"/>
      <gleif-L1:hasValidationSources>
        <xsl:attribute name="rdf:resource">
          <xsl:text>https://www.gleif.org/ontology/</xsl:text>
          <xsl:choose>
            <xsl:when test="$valsource = 'ENTITY_SUPPLIED_ONLY'">L1/ValidationSourceKindEntitySuppliedOnly</xsl:when>
            <xsl:when test="$valsource = 'FULLY_CORROBORATED'">L1/ValidationSourceKindFullyCorroborated</xsl:when>
            <xsl:when test="$valsource = 'PARTIALLY_CORROBORATED'">L1/ValidationSourceKindPartiallyCorroborated</xsl:when>
            <xsl:when test="$valsource = 'PENDING'">L1internal/ValidationSourceKindPending</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </gleif-L1:hasValidationSources>
      <!-- Validation identifier -->
      <xsl:variable name="val-reg" select="$record/lei:Registration/lei:ValidationAuthority/lei:ValidationAuthorityID"/>
      <xsl:if test="$record/lei:Registration/lei:ValidationAuthority and $val-reg != 'RA999999'">
        <xsl:variable name="val-reg-text" select="$record/lei:Registration/lei:ValidationAuthority/lei:OtherValidationAuthorityID"/>
        <xsl:variable name="val-reg-ent-id" select="$record/lei:Registration/lei:ValidationAuthority/lei:ValidationAuthorityEntityID"/>
        <xsl:variable name="val-id">
          <xsl:choose>
            <xsl:when test="$val-reg = 'RA888888' and $val-reg-text !=''">
              <xsl:value-of select="translate($val-reg-text, $invalid-id-chars, $replacement-id-chars)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$val-reg"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <gleif-L1:hasValidationIdentifier>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/L1Data/BID-</xsl:text>
            <xsl:value-of select="$val-id"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="translate(string($val-reg-ent-id), $invalid-id-chars, $replacement-id-chars)"/>
          </xsl:attribute>
        </gleif-L1:hasValidationIdentifier>
      </xsl:if>
      <!-- Other validation identifiers -->
      <xsl:for-each select="$record/lei:Registration/lei:OtherValidationAuthorities/lei:OtherValidationAuthority">
        <xsl:variable name="val-reg" select="lei:ValidationAuthorityID"/>
        <xsl:variable name="val-reg-text" select="lei:OtherValidationAuthorityID"/>
        <xsl:variable name="val-reg-ent-id" select="lei:ValidationAuthorityEntityID"/>
        <xsl:variable name="val-id">
          <xsl:choose>
            <xsl:when test="$val-reg = 'RA888888' and $val-reg-text !=''">
              <xsl:value-of select="translate($val-reg-text, $invalid-id-chars, $replacement-id-chars)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$val-reg"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <gleif-L1:hasOtherValidationIdentifier>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/L1Data/BID-</xsl:text>
            <xsl:value-of select="$val-id"/>
            <xsl:text>-</xsl:text>
            <xsl:value-of select="translate(string($val-reg-ent-id), $invalid-id-chars, $replacement-id-chars)"/>
          </xsl:attribute>
        </gleif-L1:hasOtherValidationIdentifier>
      </xsl:for-each>
    </gleif-L1:LegalEntityIdentifier>
  </xsl:template>
  
  <xsl:template match="lei:Entity | lei:Registration  
    | lei:OtherEntityNames | lei:TransliteratedOtherEntityNames | lei:OtherAddresses | lei:TransliteratedOtherAddresses" mode="rec">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="lei:LegalAddress" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-base:PhysicalAddress>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAL')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-base:PhysicalAddress>
  </xsl:template>
  
  <xsl:template match="lei:HeadquartersAddress" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-base:PhysicalAddress>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQL')"/>
      <xsl:apply-templates>
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:apply-templates>
    </gleif-base:PhysicalAddress>
  </xsl:template>
  
  <xsl:template match="lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_LEGAL_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-base:PhysicalAddress>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAA')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-base:PhysicalAddress>
  </xsl:template>
  
  <xsl:template match="lei:OtherAddress[@type='ALTERNATIVE_LANGUAGE_HEADQUARTERS_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-base:PhysicalAddress>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQA')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-base:PhysicalAddress>
  </xsl:template>
  
  <xsl:template match="lei:TransliteratedOtherAddress[@type='AUTO_ASCII_TRANSLITERATED_LEGAL_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-L1:PhysicalAddressASCII>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-L1:PhysicalAddressASCII>
  </xsl:template>
  
  <xsl:template match="lei:TransliteratedOtherAddress[@type='AUTO_ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-L1:PhysicalAddressASCII>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQT')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-L1:PhysicalAddressASCII>
  </xsl:template>
  
  <xsl:template match="lei:TransliteratedOtherAddress[@type='PREFERRED_ASCII_TRANSLITERATED_LEGAL_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-L1:PhysicalAddressASCII>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-LAT')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-L1:PhysicalAddressASCII>
  </xsl:template>
  
  <xsl:template match="lei:TransliteratedOtherAddress[@type='PREFERRED_ASCII_TRANSLITERATED_HEADQUARTERS_ADDRESS']" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="lang" select="@xml:lang"/>
    <gleif-L1:PhysicalAddressASCII>
      <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei, '-HQT')"/>
      <xsl:call-template name="do-address">
        <xsl:with-param name="lang" select="$lang"/>
      </xsl:call-template>
    </gleif-L1:PhysicalAddressASCII>
  </xsl:template>
  
  <!-- Process address elements -->
  <xsl:template name="do-address">
    <xsl:param name="lang"/>
    <xsl:apply-templates select="lei:FirstAddressLine"/>
    <xsl:for-each select="lei:AdditionalAddressLine">
      <xsl:variable name="pos-el" select="concat('gleif-base:hasAddressLine', position() + 1)"/>
      <xsl:element name="{$pos-el}">
        <xsl:if test="$lang != ''">
          <xsl:attribute name="xml:lang" select="$lang"/>
        </xsl:if>
        <xsl:value-of select="string(.)"/>
      </xsl:element>
    </xsl:for-each>
    <xsl:apply-templates select="*[not(local-name()='AdditionalAddressLine' or local-name()='FirstAddressLine')]"/>
  </xsl:template>

  <xsl:template name="camelCase">
    <xsl:param name="inString" select="@name"/>
    <xsl:variable name="initial">
      <xsl:for-each select="tokenize($inString, '\s+')">
        <xsl:choose>
          <xsl:when test="position() = 1">
            <xsl:value-of select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(upper-case(substring(., 1, 1)), substring(., 2))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="translate($initial,$invalid-id-chars, $replacement-id-chars)"/>
  </xsl:template>
  
  <xsl:template match="lei:RegistrationAuthority" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="bus-reg" select="lei:RegistrationAuthorityID"/>
    <xsl:if test="$bus-reg != 'RA999999'">
      <xsl:variable name="bus-reg-text" select="lei:OtherRegistrationAuthorityID"/>
      <xsl:variable name="bus-reg-ent-id" select="lei:RegistrationAuthorityEntityID"/>
      <xsl:variable name="reg-id">
        <xsl:choose>
          <xsl:when test="$bus-reg = 'RA888888' and $bus-reg-text != ''">
<!--            <xsl:call-template name="camelCase">
              <xsl:with-param name="inString" select="$bus-reg-text"/>
            </xsl:call-template> -->
            <xsl:value-of select="translate($bus-reg-text, $invalid-id-chars, $replacement-id-chars)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- This will use RA888888 when there is no alternative name -->
            <xsl:value-of select="$bus-reg"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <gleif-L1:BusinessRegistryIdentifier>
        <xsl:attribute name="rdf:about">
          <xsl:text>https://www.gleif.org/ontology/L1Data/BID-</xsl:text>
          <xsl:value-of select="$reg-id"/>
          <xsl:text>-</xsl:text>
          <xsl:value-of select="translate(string($bus-reg-ent-id), $invalid-id-chars, $replacement-id-chars)"/>
        </xsl:attribute>
        <gleif-L1:hasEntityID>
          <xsl:value-of select="string($bus-reg-ent-id)"/>
        </gleif-L1:hasEntityID>
        <gleif-base:identifies>
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei)"/>
        </gleif-base:identifies>
        <xsl:if test="$bus-reg != 'RA888888' and $bus-reg != 'RA999999'">
          <gleif-L1:hasRegisteredAuthority>
            <!-- Possible TODO coin a URI for registries with no code -->
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/RegistrationAuthorityData/', $bus-reg)"/>
          </gleif-L1:hasRegisteredAuthority>
        </xsl:if>
        <xsl:if test="$bus-reg-text != ''">
          <gleif-L1:hasOtherAuthority>
            <xsl:value-of select="$bus-reg-text"/>
          </gleif-L1:hasOtherAuthority>
        </xsl:if>
      </gleif-L1:BusinessRegistryIdentifier>
    </xsl:if>
  </xsl:template>
    
  <xsl:template match="lei:ValidationAuthority | lei:OtherValidationAuthority" mode="rec">
    <xsl:param name="lei"/>
    <xsl:variable name="bus-reg" select="lei:ValidationAuthorityID"/>
    <xsl:variable name="bus-reg-text" select="lei:OtherValidationAuthorityID"/>
    <xsl:variable name="bus-reg-ent-id" select="lei:ValidationAuthorityEntityID"/>
    <xsl:if test="$bus-reg != 'RA999999'">
      <gleif-L1:BusinessRegistryIdentifie>
        <xsl:variable name="reg-id">
          <xsl:choose>
            <xsl:when test="$bus-reg = 'RA888888'  and $bus-reg-text != ''">
              <!--            <xsl:call-template name="camelCase">
              <xsl:with-param name="inString" select="$bus-reg-text"/>
            </xsl:call-template> -->
              <xsl:value-of select="translate($bus-reg-text, $invalid-id-chars, $replacement-id-chars)"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- This will use RA888888 when there is no alternative name -->
              <xsl:value-of select="$bus-reg"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="rdf:about">
          <xsl:text>https://www.gleif.org/ontology/L1Data/BID-</xsl:text>
          <xsl:value-of select="$reg-id"/>
          <xsl:text>-</xsl:text>
          <xsl:value-of select="translate(string($bus-reg-ent-id), $invalid-id-chars, $replacement-id-chars)"/>
        </xsl:attribute>
        <gleif-L1:hasEntityID>
          <xsl:value-of select="string($bus-reg-ent-id)"/>
        </gleif-L1:hasEntityID>
        <gleif-base:identifies>
          <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/L1Data/L-', $lei)"/>
        </gleif-base:identifies>
        <xsl:if test="$bus-reg != 'RA888888' and $bus-reg != 'RA999999'">
          <gleif-L1:hasRegisteredAuthority>
            <!-- Possible TODO coin a URI for registries with no code -->
            <xsl:attribute name="rdf:resource" select="concat('https://www.gleif.org/ontology/RegistrationAuthorityData/', $bus-reg)"/>
          </gleif-L1:hasRegisteredAuthority>
        </xsl:if>
        <xsl:if test="$bus-reg-text != ''">
          <gleif-L1:hasOtherAuthority>
            <xsl:value-of select="$bus-reg-text"/>
          </gleif-L1:hasOtherAuthority>
        </xsl:if>
      </gleif-L1:BusinessRegistryIdentifie>
    </xsl:if>
  </xsl:template>


  <xsl:template match="lei:FirstAddressLine">
    <xsl:param name="lang"/>
    <gleif-base:hasAddressLine1>
      <xsl:if test="$lang != ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:if>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasAddressLine1> 
  </xsl:template>
  <xsl:template match="lei:AdditionalAddressLine"/> <!-- Handled inline -->
  <xsl:template match="lei:City">
    <xsl:param name="lang"/>
    <gleif-base:hasCity>
      <xsl:if test="$lang != ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:if>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasCity> 
  </xsl:template>
  <xsl:template match="lei:AddressNumber">
    <gleif-base:hasAddressNumber>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasAddressNumber> 
  </xsl:template>
  <xsl:template match="lei:AddressNumberWithinBuilding">
    <xsl:param name="lang"/>
    <gleif-base:hasAddressNumberWithinBuilding>
      <xsl:if test="$lang != ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:if>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasAddressNumberWithinBuilding> 
  </xsl:template>
  <xsl:template match="lei:MailRouting">
    <xsl:param name="lang"/>
    <gleif-base:hasMailRouting>
      <xsl:if test="$lang != ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:if>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasMailRouting> 
  </xsl:template>
  <xsl:template match="lei:PostalCode">
    <gleif-base:hasPostalCode>
      <xsl:value-of select="string(.)"/>
    </gleif-base:hasPostalCode> 
  </xsl:template>
  <xsl:template match="lei:Country">
    <gleif-base:hasCountry>
      <xsl:attribute name="rdf:resource">
        <xsl:text>https://www.omg.org/spec/LCC/Countries/ISO3166-1-CountryCodes-Adjunct/</xsl:text>
        <xsl:value-of select="string(.)"/>
       </xsl:attribute>
    </gleif-base:hasCountry> 
  </xsl:template>
  <xsl:template match="lei:Region">
    <gleif-base:hasSubdivision>
      <xsl:attribute name="rdf:resource">
        <xsl:text>https://www.omg.org/spec/LCC/Countries/ISO3166-2-SubdivisionCodes-Adjunct/</xsl:text>
        <xsl:value-of select="string(.)"/>
      </xsl:attribute>
    </gleif-base:hasSubdivision> 
  </xsl:template>
  
  
  <xsl:template match="*" priority="-1"/>
  
  </xsl:stylesheet>