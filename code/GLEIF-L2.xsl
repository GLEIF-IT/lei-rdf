<?xml version="1.0"?>
<!DOCTYPE stylesheet [
  <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
  <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
  <!ENTITY dct "http://purl.org/dc/terms/" >
  
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
  xmlns:rr="http://www.gleif.org/data/schema/rr/2016"
  xmlns:gleif="http://www.gleif.org/concatenated-file/header-extension/2.0" 
  xmlns:gleif-L1="https://www.gleif.org/ontology/L1/"
  xmlns:gleif-L1-data="https://rdf.gleif.org/L1/"
  xmlns:gleif-L2="https://www.gleif.org/ontology/L2/"
  xmlns:gleif-L2internal="https://www.gleif.org/ontology/L2internal/"
  xmlns:gleif-L2-data="https://rdf.gleif.org/L2/"
  xmlns:gleif-base="https://www.gleif.org/ontology/Base/"
  xmlns:saxon="http://saxon.sf.net/"
  
  extension-element-prefixes="gleif rr saxon">


  <!--#########################################################################-->
  <!-- Converts LEI RR CDF format version 2.1 data to RDF-->
  <!-- Uses XSLT 3.0 streaming for large data manipulation -->
  
  <!--#########################################################################-->
  
  <xsl:output method="xml" indent="yes" media-type="application/xml"  encoding="UTF-8"
    doctype-public="rdf:RDF" /> 
  <xsl:strip-space elements="*"/>
  
  <xsl:mode streamable="yes" use-accumulators="#all"/>
  
  
  <xsl:param name="percentages" select="'true'"/> <!-- Whether to include percentages which are meant to be internal only -->
  
  <xsl:variable name="invalid-id-chars" select="' /:,()&gt;&lt;&amp;'"/> <!-- Cannot be used in xmi ids -->
  
  <xsl:variable name="replacement-id-chars" select="'_..._____'"/> <!-- Substitute for above - must match in number -->
  <xsl:variable name="null-date" as="xs:dateTime">1970-01-01T00:00:00.00</xsl:variable>
  
  <xsl:variable name="root" select="/rr:RelationshipData"/>
      
  <xsl:accumulator name="header-date"  as="xs:string" streamable="yes" initial-value="''">
    <xsl:accumulator-rule match="rr:Header/rr:ContentDate/text()"
      select="."/>
  </xsl:accumulator>
  
  <xsl:template match="/rr:RelationshipData | rr:Header">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="/rr:RelationshipData/rr:RelationshipRecords">
    <rdf:RDF xml:base="https://rdf.gleif.org/L2/">
      <owl:Ontology rdf:about="https://rdf.gleif.org/L2/">
        <rdfs:label>GLEIF L2 data</rdfs:label>
        <dct:abstract>Ontology generated from GLEIF L2 data in RR 1.1 format</dct:abstract>
        <dct:issued rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
          <xsl:value-of select="accumulator-before('header-date')"/>
        </dct:issued>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/L2/"/>
        <owl:imports rdf:resource="https://rdf.gleif.org/L1/"/>
        <skos:note>There are 2 categories of individual:
          1) The LegalEntityRelationship (or a subclass). 
            The URI is a prefix of R- followed by LEIs of child then parent separated by - followed 
              by a suffix of one of -D, -U or -I for Direct, Ultimate or International Branch accounting consolidation relationships respectively;
              or one of -M, -S, -F for Managed-by, Sub-fund or Feeder-master fund relationships respectively.
          2) The LegalEntityRelationshipRecord. The URI is that of the LegalEntityRelationship followed by -REC.
        </skos:note>
      </owl:Ontology>
      <xsl:for-each select="rr:RelationshipRecord" saxon:threads="32">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:template>
  
  <xsl:template match="rr:RelationshipRecord">
    <!-- Traverse children to accumulate values, then process them -->
    <!-- Keep a record of the entry then process it - to allow streaming -->
    <xsl:variable name="record" as="element()*"> <!-- Keep track of anything interesting -->
      <xsl:copy-of select="."/>
    </xsl:variable>
    <xsl:variable name="status" as="xs:string" select="$record/rr:Relationship/rr:RelationshipStatus"/>
    <xsl:variable name="type" as="xs:string" select="$record/rr:Relationship/rr:RelationshipType"/>
    <xsl:variable name="start" as="xs:string" select="$record/rr:Relationship/rr:StartNode/rr:NodeID"/>
    <xsl:variable name="end" as="xs:string" select="$record/rr:Relationship/rr:EndNode/rr:NodeID"/>
    <xsl:variable name="el">
       <xsl:choose>
         <xsl:when test="$type='IS_DIRECTLY_CONSOLIDATED_BY'">gleif-L2:DirectConsolidation</xsl:when>
         <xsl:when test="$type='IS_ULTIMATELY_CONSOLIDATED_BY'">gleif-L2:UltimateConsolidation</xsl:when>
         <xsl:when test="$type='IS_INTERNATIONAL_BRANCH_OF'">gleif-L2:InternationalBranchRelationship</xsl:when>
         <xsl:when test="$type='IS_FUND-MANAGED_BY'">gleif-L2:FundManagementRelationship</xsl:when>
         <xsl:when test="$type='IS_SUBFUND_OF'">gleif-L2:SubFundRelationship</xsl:when>
         <xsl:when test="$type='IS_FEEDER_TO'">gleif-L2:FeederMasterFundRelationship</xsl:when>
         <xsl:otherwise>
           <xsl:message select="concat('Unknown relationship type: ', $type)"/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>
    <xsl:variable name="type-char">
      <xsl:choose>
        <xsl:when test="$type='IS_DIRECTLY_CONSOLIDATED_BY'">D</xsl:when>
        <xsl:when test="$type='IS_ULTIMATELY_CONSOLIDATED_BY'">U</xsl:when>
        <xsl:when test="$type='IS_INTERNATIONAL_BRANCH_OF'">I</xsl:when>
        <xsl:when test="$type='IS_FUND-MANAGED_BY'">M</xsl:when>
        <xsl:when test="$type='IS_SUBFUND_OF'">S</xsl:when>
        <xsl:when test="$type='IS_FEEDER_TO'">F</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$el}">
       <xsl:attribute name="rdf:about" select="concat('https://rdf.gleif.org/L2/R-', $start, '-', $end, '-' , $type-char)"/>
      <xsl:element name="gleif-L2:hasChild">
         <xsl:attribute name="rdf:resource">
           <xsl:text>https://rdf.gleif.org/L1/L-</xsl:text>
           <xsl:value-of select="$start"/>
         </xsl:attribute>
       </xsl:element>
      <xsl:element name="gleif-L2:hasParent">
         <xsl:attribute name="rdf:resource">
           <xsl:text>https://rdf.gleif.org/L1/L-</xsl:text>
           <xsl:value-of select="$end"/>
         </xsl:attribute>
       </xsl:element>
       <xsl:element name="gleif-L2:hasRelationshipStatus">
         <xsl:attribute name="rdf:resource">          
           <xsl:text>https://www.gleif.org/ontology/L2/RelationshipStatus</xsl:text>
           <xsl:choose>
              <xsl:when test="$status = 'ACTIVE'">Active</xsl:when>
              <xsl:when test="$status = 'INACTIVE'">Inactive</xsl:when>
              <xsl:when test="$status = 'NULL'">Null</xsl:when>
             <xsl:otherwise>
                <xsl:message select="concat('Unknown status: ', $status)"/>
              </xsl:otherwise>
           </xsl:choose>
         </xsl:attribute>
       </xsl:element>
       <xsl:variable name="cat" select="$record/rr:Relationship/rr:RelationshipQualifiers/rr:RelationshipQualifier[rr:QualifierDimension='ACCOUNTING_STANDARD']/rr:QualifierCategory"/>
       <xsl:if test="$cat != ''">
         <xsl:element name="gleif-L2:hasAccountingStandard">
           <xsl:attribute name="rdf:resource">
             <xsl:text>https://www.gleif.org/ontology/L2/AccountingStandard</xsl:text>
             <xsl:choose>
               <xsl:when test="$cat='IFRS'">IFRS</xsl:when>
               <xsl:when test="$cat='US_GAAP'">USGAAP</xsl:when>
               <xsl:when test="$cat='GOVERNMENT_ACCOUNTING_STANDARD'">GovernmentAccountingStandard</xsl:when>
               <xsl:when test="$cat='OTHER_ACCOUNTING_STANDARD'">OtherAccountingStandard</xsl:when>
               <xsl:otherwise>
                 <xsl:message select="concat('Unknown accounting standard: ', $cat)"/>
               </xsl:otherwise>
             </xsl:choose>
           </xsl:attribute>
         </xsl:element>
       </xsl:if>
       <xsl:if test="$percentages = 'true' and $record/rr:Relationship/rr:RelationshipQuantifiers/rr:RelationshipQuantifier[rr:QuantifierUnits='PERCENTAGE']">
         <xsl:variable name="pct" as="xs:double" select="$record/rr:Relationship/rr:RelationshipQuantifiers/rr:RelationshipQuantifier[rr:QuantifierUnits='PERCENTAGE'][1]/rr:QuantifierAmount"/>
         <xsl:if test="count($record/rr:Relationship/rr:RelationshipQuantifiers/rr:RelationshipQuantifier[rr:QuantifierUnits='PERCENTAGE']) &gt; 1">
          <xsl:message select="concat($type, ' relationship from ', $start, ' to ', $end, 'has 2 percentages')"/>
         </xsl:if>
         <xsl:variable name="adj-pct">
           <xsl:choose>
             <xsl:when test="$pct = 1.00">
               <xsl:value-of select="100"/>
             </xsl:when>
             <xsl:otherwise>
               <xsl:value-of select="$pct"/>
             </xsl:otherwise>
           </xsl:choose>
         </xsl:variable>
         <xsl:if test="$adj-pct != '' and $adj-pct != 'NaN'">
           <xsl:element name="gleif-L2internal:hasOwnershipPercentage">
             <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#decimal</xsl:attribute>
             <xsl:value-of select="$adj-pct"/>
           </xsl:element>
         </xsl:if>
       </xsl:if>
      <xsl:for-each select="$record/rr:Relationship/rr:RelationshipPeriods/rr:RelationshipPeriod[rr:PeriodType='RELATIONSHIP_PERIOD']">
        <gleif-L2:hasRelationshipPeriod>
          <xsl:call-template name="ProcessPeriod"/>
        </gleif-L2:hasRelationshipPeriod>
      </xsl:for-each>
     </xsl:element>
    
    <gleif-L2:LegalEntityRelationshipRecord>
      <xsl:attribute name="rdf:about" select="concat('https://rdf.gleif.org/L2/R-', $start, '-', $end, '-' , $type-char, '-REC')"/>
      <gleif-base:records>
        <xsl:attribute name="rdf:resource" select="concat('https://rdf.gleif.org/L2/R-', $start, '-', $end, '-' , $type-char)"/>
      </gleif-base:records>
      <xsl:if test="$record/rr:Registration/rr:InitialRegistrationDate">
         <gleif-base:hasInitialRegistrationDate rdf:datatype="&xsd;dateTime">
           <xsl:value-of select="$record/rr:Registration/rr:InitialRegistrationDate"/>
         </gleif-base:hasInitialRegistrationDate>
      </xsl:if>
      <xsl:if test="$record/rr:Registration/rr:LastUpdateDate">
       <gleif-base:hasLastUpdateDate rdf:datatype="&xsd;dateTime">
         <xsl:value-of select="$record/rr:Registration/rr:LastUpdateDate"/>
       </gleif-base:hasLastUpdateDate>
      </xsl:if>
      <xsl:variable name="regstat" select="$record/rr:Registration/rr:RegistrationStatus"/>
      <gleif-base:hasRegistrationStatus>
        <xsl:attribute name="rdf:resource">
          <xsl:text>https://www.gleif.org/ontology/</xsl:text>
          <xsl:choose>
            <xsl:when test="$regstat = 'ANNULLED'">L2/RegistrationStatusAnnulled</xsl:when>
            <xsl:when test="$regstat = 'DUPLICATE'">L2/RegistrationStatusDuplicate</xsl:when>
            <xsl:when test="$regstat = 'LAPSED'">L2/RegistrationStatusLapsed</xsl:when>
            <xsl:when test="$regstat = 'PUBLISHED'">L2/RegistrationStatusPublished</xsl:when>
            <xsl:when test="$regstat = 'PENDING_ARCHIVAL'">L2/RegistrationStatusPendingArchival</xsl:when>
            <xsl:when test="$regstat = 'PENDING_TRANSFER'">L2/RegistrationStatusPendingTransfer</xsl:when>
            <xsl:when test="$regstat = 'PENDING_VALIDATION'">L2internal/RegistrationStatusPendingValidation</xsl:when>
            <xsl:when test="$regstat = 'RETIRED'">L2/RegistrationStatusRetired</xsl:when>
            <xsl:when test="$regstat = 'TRANSFERRED'">L2internal/RegistrationStatusTransferred</xsl:when>
            <xsl:otherwise>
              <xsl:message select="concat('Unknown relationship registration status: ', $regstat)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </gleif-base:hasRegistrationStatus>
      <xsl:if test="$record/rr:Registration/rr:NextRenewalDate">
       <gleif-base:hasNextRenewalDate rdf:datatype="&xsd;dateTime">
         <xsl:value-of select="$record/rr:Registration/rr:NextRenewalDate"/>
       </gleif-base:hasNextRenewalDate>
      </xsl:if>
      <!-- Periods -->
      <xsl:for-each select="$record/rr:Relationship/rr:RelationshipPeriods/rr:RelationshipPeriod[rr:PeriodType='ACCOUNTING_PERIOD']">
        <gleif-L2:hasAccountingPeriod>
          <xsl:call-template name="ProcessPeriod"/>
        </gleif-L2:hasAccountingPeriod>
      </xsl:for-each>
      <xsl:for-each select="$record/rr:Relationship/rr:RelationshipPeriods/rr:RelationshipPeriod[rr:PeriodType='DOCUMENT_FILING_PERIOD']">
        <gleif-L2:hasDocumentFilingPeriod>
          <xsl:call-template name="ProcessPeriod"/>
        </gleif-L2:hasDocumentFilingPeriod>
      </xsl:for-each>
      <!-- Management -->
      <gleif-L1:hasManagingLOU>
        <xsl:attribute name="rdf:resource" select="concat('https://rdf.gleif.org/L1/L-', $record/rr:Registration/rr:ManagingLOU)"/>
      </gleif-L1:hasManagingLOU>
      <xsl:for-each select="$record/rr:Registration/rr:ValidationSources">
        <gleif-L2:hasValidationSources>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/</xsl:text>
            <xsl:choose>
              <xsl:when test=". = 'ENTITY_SUPPLIED_ONLY'">L1/ValidationSourceKindEntitySuppliedOnly</xsl:when>
              <xsl:when test=". = 'FULLY_CORROBORATED'">L1/ValidationSourceKindFullyCorroborated</xsl:when>
              <xsl:when test=". = 'PARTIALLY_CORROBORATED'">L1/ValidationSourceKindPartiallyCorroborated</xsl:when>
              <xsl:otherwise>
                <xsl:message select="concat('Unknown validation sources: ', .)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </gleif-L2:hasValidationSources>
      </xsl:for-each>
      <xsl:for-each select="$record/rr:Registration/rr:ValidationDocuments">
        <gleif-base:hasValidationDocuments>
          <xsl:attribute name="rdf:resource">
            <xsl:text>https://www.gleif.org/ontology/Base/ValidationDocumentsKind</xsl:text>
            <xsl:choose>
              <xsl:when test=". = 'ACCOUNTS_FILING'">AccountsFiling</xsl:when>
              <xsl:when test=". = 'CONTRACTS'">Contracts</xsl:when>
              <xsl:when test=". = 'OTHER_OFFICIAL_DOCUMENTS'">OtherOfficialDocuments</xsl:when>
              <xsl:when test=". = 'REGULATORY_FILING'">RegulatoryFiling</xsl:when>
              <xsl:when test=". = 'SUPPORTING_DOCUMENTS'">SupportingDocuments</xsl:when>
              <xsl:otherwise>
                <xsl:message select="concat('Unknown validation documents: ', .)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </gleif-base:hasValidationDocuments>
      </xsl:for-each>
      <xsl:for-each select="$record/rr:Registration/rr:ValidationReference">
        <gleif-base:hasValidationReference>
          <xsl:copy-of select="xml:lang"/>
          <xsl:value-of select="normalize-unicode(string(.), 'NFKC')"/>
        </gleif-base:hasValidationReference>
      </xsl:for-each>
    </gleif-L2:LegalEntityRelationshipRecord>
  </xsl:template>

  <xsl:template name="ProcessPeriod">
    <gleif-base:Period>
      <xsl:if test="rr:StartDate">
        <gleif-base:hasStart rdf:datatype="&xsd;dateTime">
          <xsl:value-of select="rr:StartDate"/>
        </gleif-base:hasStart>
      </xsl:if>
      <xsl:if test="rr:EndDate">
        <gleif-base:hasEnd rdf:datatype="&xsd;dateTime">
          <xsl:value-of select="rr:EndDate"/>
        </gleif-base:hasEnd>
      </xsl:if>
    </gleif-base:Period>
  </xsl:template>

  <xsl:template match="*" priority="-1"/>
   
  </xsl:stylesheet>
