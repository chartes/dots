<?xml version="1.0" encoding="UTF-8"?>
<!-- 
Compilation des cates en ancien français
-->
<xsl:transform version="1.1" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei"
>
  <xsl:output encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
  <!-- -->
  <!-- défaut : copie tout -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  <!-- éléments arrêtés -->
  <xsl:template match="
      tei:teiHeader 
    | /tei:TEI/tei:text/tei:front 
    | /tei:TEI/tei:text/tei:back 
  "/>
  <!-- éléments de structure traversés sans trace -->
  <xsl:template match="
      /
    | /tei:TEI 
    | /tei:TEI/tei:text
  ">
    <xsl:apply-templates select="*"/>
  </xsl:template>
  <xsl:template match="tei:group">
    <xsl:choose>
      <xsl:when test="not(.//tei:div[@type='transcription'][@xml:lang='fro'])"/>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  <!-- Retenir les actes en latin -->
  <xsl:template match="tei:text">
    <xsl:choose>
      <xsl:when test="tei:body/tei:div[@xml:lang='lat']"/>
      <!-- français moderne (Montmartre) -->
      <xsl:when test="tei:body/tei:div[@xml:lang='fra']"/>
      <xsl:when test="not(tei:body/tei:div)"/>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*[@xml:lang='lat']"/>
</xsl:transform>
