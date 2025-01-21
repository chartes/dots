<?xml version="1.0" encoding="UTF-8"?>
<!--
Une solution légère pour des statistiques lexicales sur du XML
Merci Michael Kay et Dave Pawson !
http://dpawson.co.uk/xsl/rev2/functions2.html#d15168e376
-->
<xsl:transform version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei"
>
  <xsl:output indent="yes"/>
  <!-- liste de balises incluses (séparées d'espaces) -->
  <xsl:param name="include"/>
  <!-- listes de balises exclues (séparées d'espaces) -->
  <xsl:param name="exclude">  </xsl:param>
  <!-- titre du fichier -->
  <xsl:param name="title" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]"/>
  <xsl:template match="/">
    <html><head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <title>
        <xsl:value-of select="$title"/>
      </title>
      <link rel="stylesheet" type="text/css" href="../../2diple/theme/diple_doc.css"/>
    </head>
    <body>
      <!-- Récupérer les chaînes qui m'intéressent -->
      <xsl:variable name="text">
        <xsl:apply-templates select=".//tei:div[@type='transcription']" mode="mots"/>
      </xsl:variable>
      <xsl:variable name="seps"  > .,;:?!¶§†ª—«»()*\-0-9\[\]&amp;&apos;&quot;</xsl:variable>
      <xsl:variable name="spaces">                              </xsl:variable>
      <xsl:variable name="mots">
        <xsl:for-each-group group-by="." select="
          for $w in tokenize(
            translate($text, $seps, $spaces),
            '[\s]+' 
          )[.] return lower-case($w)
        ">
          <xsl:sort select="count(current-group())" order="descending"/>
          <mot>
            <xsl:attribute name="form">
              <xsl:value-of select="current-grouping-key()"/>
            </xsl:attribute>
            <xsl:attribute name="count">
              <xsl:value-of select="count(current-group())"/>
            </xsl:attribute>
          </mot>
        </xsl:for-each-group>
      </xsl:variable>
      <h1><xsl:value-of select="$title"/>, statistiques lexicales</h1>
      <h2>Majuscules</h2>
      <pre>
        <xsl:for-each-group group-by="." select="
          for $w in tokenize(
            translate($text, $seps, $spaces),
            '[\s]+' 
          )[.] return $w
        ">
          <!-- marche pas lang="fr" data-type="text" case-order="upper-first" -->
          <xsl:sort 
collation="http://saxon.sf.net/collation?lang=fr"
select="current-grouping-key()" order="ascending"/>
          <xsl:if test="lower-case(.) != .">
            <xsl:text>
</xsl:text>
            <xsl:value-of select="current-grouping-key()"/>
            <xsl:text>  </xsl:text>
            <xsl:value-of select="count(current-group())"/>
          </xsl:if>
        </xsl:for-each-group>
      </pre>
      <h2 id="voc">Vocabulaire</h2>
      <pre>
        <xsl:for-each select="$mots/*">
          <!-- marche pas lang="fr" data-type="text" case-order="upper-first" -->
          <xsl:sort 
collation="http://saxon.sf.net/collation?lang=fr"
select="@form" order="ascending"/>
          <xsl:text>
</xsl:text>
          <xsl:value-of select="@form"/>
          <xsl:text>  </xsl:text>
          <xsl:value-of select="substring('                 ', string-length(@form))"/>
          <xsl:value-of select="@count"/>
        </xsl:for-each>
      </pre>
      <h2 id="freq">Fréquences</h2>
      <pre>
        <xsl:for-each select="$mots/*">
          <!-- marche pas lang="fr" case-order="upper-first" -->
          <xsl:sort select="@count" data-type="number" order="descending"/>
          <xsl:text>
</xsl:text>
          <xsl:value-of select="substring('     ', string-length(@count))"/>
          <xsl:value-of select="@count"/>
          <xsl:text>  </xsl:text>
          <xsl:value-of select="@form"/>
        </xsl:for-each>
      </pre>
    </body>
    </html>
  </xsl:template> 

  <!-- mode mots, traverser toutes les balises, sortir tout le texte, retenir certaines balises -->
  <xsl:template match="tei:name | tei:rs | tei:persName | tei:placeName | tei:num | tei:abbr | tei:date" mode="mots"/>

</xsl:transform>
