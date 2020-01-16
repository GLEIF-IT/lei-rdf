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
  xmlns:repex="http://www.gleif.org/data/schema/repex/2016"
  xmlns:gleif="http://www.gleif.org/concatenated-file/header-extension/2.0" 
  xmlns:gleif-L1="https://www.gleif.org/ontology/L1/"
  xmlns:gleif-L1-data="https://www.gleif.org/ontology/L1Data/"
  xmlns:gleif-L2="https://www.gleif.org/ontology/L2/"
  xmlns:gleif-repex="https://www.gleif.org/ontology/ReportingException/"
  xmlns:gleif-repex-data="https://www.gleif.org/ontology/ReportingExceptionData/"
  xmlns:gleif-base="https://www.gleif.org/ontology/Base/"
  xmlns:saxon="http://saxon.sf.net/"
  
  extension-element-prefixes="gleif repex saxon">


  <!--#########################################################################-->
  <!-- Converts LEI RepEx 1.1 format data to RDF-->
  <!-- Uses XSLT 3.0 streaming for large data manipulation -->
  
  <!--#########################################################################-->
  
  <xsl:output method="xml" indent="yes" media-type="application/xml" 
    doctype-public="rdf:RDF" /> 
  <xsl:strip-space elements="*"/>
  
  <xsl:mode streamable="yes" use-accumulators="#all"/>
  
  <xsl:param name="percentages" select="'true'"/> <!-- Whether to include percentages which are meant to be iunternal only -->
  
  <xsl:variable name="invalid-id-chars" select="' /:,()&gt;&lt;&amp;'"/> <!-- Cannot be used in xmi ids -->
  
  <xsl:variable name="replacement-id-chars" select="'_..._____'"/> <!-- Substitute for above - must match in number -->
  <xsl:variable name="null-date" as="xs:dateTime">1970-01-01T00:00:00.00</xsl:variable>
  
  <xsl:accumulator name="header-date"  as="xs:string" streamable="yes" initial-value="''">
    <xsl:accumulator-rule match="repex:Header/repex:ContentDate/text()"
      select="."/>
  </xsl:accumulator>
  
  <xsl:template match="/repex:ReportingExceptionData | repex:Header">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="/repex:ReportingExceptionData/repex:ReportingExceptions">    
    <rdf:RDF xml:base="https://www.gleif.org/ontology/ReportingExceptionData/">
      <owl:Ontology rdf:about="https://www.gleif.org/ontology/ReportingExceptionData/">
        <rdfs:label>GLEIF RepEx data</rdfs:label>
        <dct:abstract>Ontology generated from GLEIF Reporting Exception data in RepEx 1.1 format</rdfs:label>
        <dct:issued rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
          <xsl:value-of select="accumulator-before('header-date')"/>
        </dct:issued>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/L2/"/>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/ReportingException/"/>
        <owl:imports rdf:resource="https://www.gleif.org/ontology/L1Data/"/>
      </owl:Ontology>
      <xsl:for-each select="repex:ReportingExceptionData/repex:ReportingExceptions/repex:Exception" saxon:threads="32">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </rdf:RDF>
  </xsl:template>
  
  <xsl:template match="repex:Exception">
    <!-- Traverse children to accumulate values, then process them -->
    <!-- Keep a record of the entry then process it - to allow streaming -->
    <xsl:variable name="record" as="element()*"> <!-- Keep track of anything interesting -->
      <xsl:copy-of select="."/>
    </xsl:variable>
    <xsl:variable name="type" as="xs:string" select="$record/repex:ExceptionCategory"/>
    <xsl:variable name="lei" as="xs:string" select="$record/repex:LEI"/>
    <xsl:variable name="el">
       <xsl:choose>
         <xsl:when test="$type='DIRECT_ACCOUNTING_CONSOLIDATION_PARENT'">gleif-repex:DirectConsolidationReportingException</xsl:when>
         <xsl:when test="$type='ULTIMATE_ACCOUNTING_CONSOLIDATION_PARENT'">gleif-repex:UltimateConsolidationReportingException</xsl:when>
         <xsl:otherwise>
           <xsl:message select="concat('Unknown exception category: ', $type)"/>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>
    <xsl:variable name="type-char">
      <xsl:choose>
        <xsl:when test="$type='DIRECT_ACCOUNTING_CONSOLIDATION_PARENT'">D</xsl:when>
        <xsl:when test="$type='ULTIMATE_ACCOUNTING_CONSOLIDATION_PARENT'">U</xsl:when>
        <xsl:otherwise>
          <xsl:message select="concat('Unknown exception category: ', $type, ' using -K')"/>
          <xsl:text>K</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$el}">
       <xsl:attribute name="rdf:about" select="concat('https://www.gleif.org/ontology/ReportingExceptionData/X-', $lei, '-', $type-char)"/>
      <xsl:element name="gleif-repex:hasReportingEntity">
         <xsl:attribute name="rdf:resource">
           <xsl:text>https://www.gleif.org/ontology/L1Data/L-</xsl:text>
           <xsl:value-of select="$lei"/>
         </xsl:attribute>
       </xsl:element>
      <!-- It is possible to have more than one reason -->
      <xsl:for-each select="$record/repex:ExceptionReason">
        <xsl:variable name="reason" as="xs:string" select="."/>
        <xsl:element name="gleif-repex:hasExceptionReason">
           <xsl:attribute name="rdf:resource">          
             <xsl:text>gleif-repex:ExceptionReasonKind</xsl:text>
             <xsl:choose>
               <xsl:when test="$reason = 'BINDING_LEGAL_COMMITMENTS'">BindingLegalCommitments</xsl:when>
               <xsl:when test="$reason = 'CONSENT_NOT_OBTAINED'">ConsentNotObtained</xsl:when>
               <xsl:when test="$reason = 'DETRIMENT_NOT_EXCLUDED'">DetrimentNotExcluded</xsl:when>
               <xsl:when test="$reason = 'DISCLOSURE_DETRIMENTAL'">DisclosureDetrimental</xsl:when>
               <xsl:when test="$reason = 'LEGAL_OBSTACLES'">LegalObstacles</xsl:when>
               <xsl:when test="$reason = 'NATURAL_PERSONS'">NaturalPersons</xsl:when>
               <xsl:when test="$reason = 'NO_KNOWN_PERSON'">NoKnownPerson</xsl:when>
               <xsl:when test="$reason = 'NO_LEI'">NoLEI</xsl:when>
               <xsl:when test="$reason = 'NON_CONSOLIDATING'">NonConsolidating</xsl:when>
               <xsl:otherwise>
                  <xsl:message select="concat('Unknown reason: ', $reason, ' for LEI: ', $lei)"/>
                </xsl:otherwise>
             </xsl:choose>
           </xsl:attribute>
         </xsl:element>
       </xsl:for-each>
       <xsl:for-each select="$record/repex:ExceptionReference">
         <xsl:element name="gleif-repex:hasExceptionReference">
           <xsl:copy-of select="@xml:lang"/>
           <xsl:value-of select="."/>
         </xsl:element>
       </xsl:for-each>
     </xsl:element>
  </xsl:template>    

  <xsl:template match="*" priority="-1"/>
   
  </xsl:stylesheet>