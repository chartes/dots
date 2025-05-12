<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs html tei"
    version="2.0">
    <xsl:import href="../hteiml/tei2html.xsl"/>
    <xsl:output encoding="UTF-8" indent="yes" method="xml" doctype-system=""/>
    <xsl:template match="tei:teiHeader"/>
    <xsl:template match="tei:TEI/tei:text/tei:body/tei:byline">
        <div class="titlepage">
            <xsl:choose>
                <xsl:when test="not(contains(text()[1],'par'))">
                    <xsl:text>par </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="text()"/>
                </xsl:otherwise>
            </xsl:choose>
            <div class="name">
                <xsl:apply-templates select="tei:forename"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates select="tei:surname"/>
            </div>
            <xsl:if test="child::tei:roleName">
                <div class="roleName">
                    <xsl:apply-templates select="tei:roleName"/>
                </div>
            </xsl:if>
            <hr width="30%" noshade="noshade" align="center"/>
        </div>
    </xsl:template>
</xsl:stylesheet>
