<?xml version="1.0"?>
<!DOCTYPE stylesheet>

<xsl:stylesheet  version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:loc="http://my.local"
    
    extension-element-prefixes="saxon loc">
    
    <!--#########################################################################-->
    <!-- Converts RDF-XML to Turtle -->
    <!-- Assumes all triples for a resource are together nested under the same element -->
    <!-- Declares and substitutes prefixes defined in SPARQL/Turtle 1.1 format in local file prefixes.ttl -->
    
    <!-- Uses XSLT 3.0 streaming for large data manipulation -->
    <!-- Streaming and multi-threading implementation require Saxon Enterprise Edition (EE) -->
    
    <!-- Copyright (c) 2021 agnos.ai UK Ltd. -->
    <!-- Licensed under Creative Commons Attribution 4.0 International Public License
        https://creativecommons.org/licenses/by/4.0/legalcode -->
    
    <!--#########################################################################-->
    
    <xsl:output method="text"  media-type="text/turtle" encoding="UTF-8"/>
    <xsl:mode streamable="yes"/>
    

    <xsl:variable name="ttl-syntax-chars" select="'~.-!$&amp;&apos;&apos;()*+,;=/?#@%_'"/> <!-- Cannot be used in xmi ids -->
    <xsl:variable name="replacement-id-chars" select="'_....._________..'"/> <!-- Substitute for above - must match in number -->

    <xsl:variable name="indent" as="xs:integer" select="2"/> <!-- each level of indentation -->
    <xsl:variable name="raw-prefixes" as="xs:string" select="unparsed-text('prefixes.ttl')"/>

    <!-- outputs n spaces -->
    <xsl:function name="loc:indenter">
        <xsl:param name="spaces" as="xs:integer"/>
        <xsl:for-each select="1 to $spaces">
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:function>

    <!-- creates a uri using local prefix if present -->
    <xsl:function name="loc:create-uri">
        <xsl:param name="url"/>
        <xsl:param name="prefix-map" as="map(xs:string, xs:string)"/>
        <xsl:variable name="namespace">
            <xsl:choose>
                <xsl:when test="ends-with($url, '#') or ends-with($url, '/')">
                    <xsl:value-of select="$url"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- strip off anything after last # or / -->
                    <xsl:value-of select="replace($url,'(.+[/#])(.*)', '$1')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        <xsl:variable name="clean-url">
            <!-- Check the url does not end with TTL syntax char -->
            <xsl:choose>
                <xsl:when test="contains($ttl-syntax-chars, substring($url, string-length($url), 1))">
                    <xsl:value-of select="substring($url, 1, string-length($url) - 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$url"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="prefix" select="$prefix-map($namespace)"/>
        <xsl:choose>
            <xsl:when test="$prefix != ''">
                <xsl:value-of select="concat($prefix, ':', substring-after($clean-url, $namespace))"/>                            
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat('Warning: no prefix found for ', $url, ' - full URI used ')"/>
                <xsl:value-of select="concat('&lt;', $clean-url, '&gt;')"/>                       
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>  

    <xsl:template match="/rdf:RDF">
        <!-- Output namespace prefixes here -->
        <xsl:value-of select="$raw-prefixes"/>
        
        <!-- Create map for the prefixes -->
        <!-- First create a list of pairs -->
        <xsl:variable name="prefix-entries" as="item()*">
            <xsl:analyze-string select="$raw-prefixes" regex="prefix (.*): &lt;(.+)&gt;">
                <xsl:matching-substring>
                    <xsl:sequence select="[regex-group(2), regex-group(1)]"/>
                </xsl:matching-substring>            
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="prefix-map" as="map(xs:string, xs:string)" 
            select="map:merge(for $e in $prefix-entries return map:entry($e(1), $e(2)))"/>       
        <!-- Main processing -->
        <xsl:text>&#x0A;</xsl:text>
        <xsl:for-each select="*" saxon:threads="32">
            <xsl:apply-templates select=".">
                <xsl:with-param name="prefix-map" select="$prefix-map"/>
            </xsl:apply-templates>
            <xsl:text>.&#x0A;</xsl:text>        
        </xsl:for-each>       
    </xsl:template>
    
    <xsl:template match="*">
        <xsl:param name="prefix-map" as="map(xs:string, xs:string)"/>
        <xsl:param name="currind" as="xs:integer" select="0"/>
        <!-- Keep a snapshot of the entry then process it - to allow streaming without backtracking -->
        <xsl:variable name="el" as="element()*"> 
            <xsl:copy-of select="."/>
        </xsl:variable>
        <xsl:value-of select="loc:indenter($currind)"/>
        <xsl:if test="$el/@rdf:about">
            <xsl:value-of select="loc:create-uri($el/@rdf:about, $prefix-map)"/>
        </xsl:if>
        <xsl:text>&#x0A;</xsl:text>
        <xsl:variable name="newind" select="$currind + $indent"/>
        <xsl:value-of select="loc:indenter($newind)"/>
        <xsl:text>a </xsl:text>
        <xsl:value-of select="$el/name()"/> <!-- assumes this uses a namespace -->
        <xsl:text> ;&#x0A;</xsl:text>
        <xsl:for-each select="$el/*">
            <xsl:value-of select="loc:indenter($newind)"/>
            <!-- use abbreviation for rdf:type -->
            <xsl:choose>
                <xsl:when test="name()='rdf:type'">a</xsl:when>
                 <xsl:otherwise>
                    <xsl:value-of select="name()"/> <!-- assumes this uses a namespace -->                    
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="@rdf:resource">
                    <!-- ObjectProperty -->
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="loc:create-uri(@rdf:resource, $prefix-map)"/>
                    <xsl:text> ;&#x0A;</xsl:text>
                </xsl:when>
                <xsl:when test="@rdf:datatype">
                    <!-- DatatypeProperty with explicit datatype -->
                    <xsl:text> "</xsl:text>
                    <xsl:value-of select="replace(replace(., '\\', '\\\\'), '&quot;+', '\\&quot;')"/>
                    <xsl:text>"</xsl:text>
                    <xsl:text>^^</xsl:text>
                    <xsl:value-of select="loc:create-uri(@rdf:datatype, $prefix-map)"/>
                    <xsl:text> ;&#x0A;</xsl:text>
                </xsl:when>
                <xsl:when test="element()">
                    <!-- Property that's a blank node -->
                    <xsl:text> [</xsl:text>
                    <xsl:for-each select="*">
                        <!-- Recurse for node itself -->
                        <xsl:apply-templates select=".">            
                            <xsl:with-param name="currind" select="$newind"/>
                            <xsl:with-param name="prefix-map" select="$prefix-map"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                    <xsl:value-of select="loc:indenter($newind)"/>
                    <xsl:text>] ;&#x0A;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Default is a (string) literal DatatypeProperty, possibly with lang tag -->
                    <!-- Special treatment for multi-line strings -->
                    <!-- Escape \ and convert any number of consecutive " to a single \" -->
                    <xsl:choose>
                        <xsl:when test="contains(., '&#x0A;')">
                            <xsl:text> """</xsl:text>
                            <xsl:value-of select="replace(replace(., '\\', '\\\\'), '&quot;+', '\\&quot;')"/>
                            <xsl:text>"""</xsl:text>                            
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text> "</xsl:text>
                            <xsl:value-of select="replace(replace(., '\\', '\\\\'), '&quot;+', '\\&quot;')"/>
                            <xsl:text>"</xsl:text>                                
                        </xsl:otherwise>
                    </xsl:choose>                        
                    <xsl:if test="@xml:lang">
                        <xsl:text>@</xsl:text>
                        <xsl:value-of select="@xml:lang"/>
                    </xsl:if>
                    <xsl:text> ;&#x0A;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:value-of select="loc:indenter($currind)"/>
    </xsl:template>
        
</xsl:stylesheet>