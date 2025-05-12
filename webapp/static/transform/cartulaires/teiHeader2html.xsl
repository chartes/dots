<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform   version="1.1"   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:eg="http://www.tei-c.org/ns/Examples"
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  exclude-result-prefixes="eg html rng tei epub"
  
  xmlns:exslt="http://exslt.org/common"
  extension-element-prefixes="exslt"
  >
  
  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes"/>
  
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="tei:TEI">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
      <head>
        <meta http-equiv="Content-type" content="text/html; charset=UTF-8" />
        <!-- déclaration classes css locale (permettre la surcharge si généralisation) -->
        <!-- à travailler
            <xsl:apply-templates select="/*/tei:teiHeader/tei:encodingDesc/tei:tagsDecl"/>
            -->
        <!--<link rel="stylesheet" type="text/css" href="{$theme}html.css"/>
            <link rel="stylesheet" type="text/css" href="{$theme}teipub.css"/>-->
        <link rel="stylesheet" type="text/css" href="/static/transform/hteiml/html.css"/>
        <link rel="stylesheet" type="text/css" href="/static/transform/hteiml/teipub.css"/>
        <script type="text/javascript" src="/static/transform/hteiml/Tree.js">//</script>
      </head>
      <body>
        <div id="aside">to delete</div>
        <div id="center">
          <div id="main">
            <div id="articel"><xsl:apply-templates select="tei:text"/></div>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template match="tei:text">
    <xsl:apply-templates select="tei:front"/>
  </xsl:template>
  
  <xsl:template match="tei:front">
    <article id="index" class="front">
      <h1 class="head"><xsl:apply-templates select="tei:head[1]"/><xsl:apply-templates select="tei:head[2]"/></h1>
      <div class="argument">
        <xsl:apply-templates select="tei:argument"/>
      </div>
      <p class="byline">
        <xsl:apply-templates select="tei:byline"/>
      </p>
    </article>
  </xsl:template>
  
  <xsl:template match="tei:argument">
    <xsl:apply-templates select="tei:p"/>
  </xsl:template>
  
  <xsl:template match="tei:p">
    <p><xsl:apply-templates/></p>
  </xsl:template>
  
  <xsl:template match="tei:hi">
    <xsl:choose>
      <xsl:when test="@rend='sup'"><sup><xsl:apply-templates/></sup></xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="tei:graphic">
    <xsl:param name="desc"><xsl:value-of select='tei:desc'/></xsl:param>
    <img src="/static/img/{@url}" alt="{$desc}"/>
  </xsl:template>
  
  <xsl:template match="tei:byline">
    <xsl:apply-templates/>
  </xsl:template>
  
</xsl:transform>
