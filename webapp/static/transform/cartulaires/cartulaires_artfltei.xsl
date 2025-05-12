<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:tei="http://www.tei-c.org/ns/1.0"
>
<xsl:strip-space elements="*"/>
<xsl:output indent="no" method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="tei:TEI">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="tei:teiHeader"/>

<xsl:template match="tei:TEI/tei:text">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="tei:text">
<xsl:document href="{$artfldir}cartulaireIdF{@xml:id}.xml">
<TEI><xsl:text>
</xsl:text>
<teiHeader><xsl:text>
</xsl:text>
<fileDesc><xsl:text>
</xsl:text>
<xsl:apply-templates select="tei:front"/>
</fileDesc><xsl:text>
</xsl:text>
</teiHeader><xsl:text>
</xsl:text>
<text><xsl:text>
</xsl:text>
<body><xsl:text>
</xsl:text>
<div id="{@xml:id}">
<xsl:apply-templates select="tei:body"/>
</div>
</body><xsl:text>
</xsl:text>
</text><xsl:text>
</xsl:text>
</TEI><xsl:text>
</xsl:text>
</xsl:document>
</xsl:template>


<xsl:template match="tei:front">
<publicationStmt>
<idno><xsl:value-of select="parent::text[substring-before(@xml:id,'-')]"/></idno>
</publicationStmt>
<sourceDesc><xsl:text>
</xsl:text>
<bibl><xsl:text>
</xsl:text>
<date><xsl:value-of select="docDate/date[substring(@notAfter,1,4)]"/>
<xsl:value-of select="docDate/date[substring(@when,1,4)]"/>
</date>
<title>
<xsl:apply-templates/>
</title>
</bibl><xsl:text>
</xsl:text>
</sourceDesc><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="tei:titlePart | tei:date | tei:docDate | tei:head | tei:div[@type='tradition']">
<xsl:apply-templates/><xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="tei:body">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="tei:group/tei:body">
<body><xsl:text>
</xsl:text>
<xsl:apply-templates/>
</body><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="tei:div">
<div n="{@n}" id="{@xml:id}" type="{@type}"><xsl:text>
</xsl:text>
<xsl:apply-templates/>
</div><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="tei:hi[@rend='i']"><hi rend="italic"><xsl:apply-templates/></hi></xsl:template>

<xsl:template match="tei:q">« <xsl:apply-templates/> »</xsl:template>

<xsl:template match="@*|node()" priority="-8">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

<xsl:template match="tei:TEI/tei:text/tei:front | tei:back | tei:bibl | tei:note | tei:listWit | witness"/>

</xsl:stylesheet>
