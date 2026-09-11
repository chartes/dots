<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:dts="https://w3id.org/dts/api#"
  version="1.0">
  
  <xsl:import href="Stylesheets/html/html.xsl"/>
   
  <xsl:template match="/tei:TEI">
    <xsl:choose>
      <!-- fragment -->
      <xsl:when test="./*[1][self::dts:wrapper]">
        <xsl:apply-templates/>
      </xsl:when>
      <!-- document -->
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="dts:wrapper">
      <article>
        <xsl:apply-templates/>
      </article>
  </xsl:template>
  
</xsl:stylesheet>