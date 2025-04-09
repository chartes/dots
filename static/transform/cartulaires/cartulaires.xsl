<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei"
>
  <!-- Keep this import order  -->
  <xsl:import href="cartulaires_html.xsl"/>
  <xsl:import href="../hteiml/tei2html.xsl"/>
  <!-- Dossier où retrouver des ressources de thème -->
  <xsl:param name="theme">../theme/</xsl:param>
  <xsl:template match="tei:group" mode="meta">
    <link rel="dc:isPartOf" href="../" title="Cartulaires d'Île-de-France"/>
  </xsl:template>
  <!-- Métas spécifiques au corpus -->
  <xsl:template match="tei:group/tei:text" mode="meta">
    <xsl:apply-templates select="tei:front/tei:docDate/tei:date" mode="meta"/>
    <meta name="dc:temporal" content="{normalize-space(tei:front/tei:docDate)}"/>
    <xsl:apply-templates select="tei:front/tei:index/tei:term" mode="meta"/>
    <xsl:variable name="description">
      <xsl:choose>
        <xsl:when test="tei:front/tei:argument">
          <xsl:value-of select="tei:front/tei:argument"/>
        </xsl:when>
        <xsl:when test="tei:front/tei:head">
          <xsl:value-of select="tei:front/tei:head"/>
        </xsl:when>
      </xsl:choose>      
    </xsl:variable>
    <xsl:if test="$description != ''">
      <meta name="description" content="{$description}"/>
    </xsl:if>
    <meta name="dc:lang" content="{tei:body/tei:div/@xml:lang}"/>
    <link rel="dc:isPartOf" href="../" title="Cartulaires d'Île-de-France"/>
  </xsl:template>
  <xsl:template match="tei:term[@type='nature']" mode="meta">
    <xsl:if test="@key and @key != ''">
      <meta name="nature" content="{@key}"/>
    </xsl:if>
  </xsl:template>
  <!-- Inscrire la date d'un acte en meta HTML, sert aussi à l'indexation -->
  <xsl:variable name="circa" select="5"/>
  <xsl:variable name="antepost" select="50"/>
  <xsl:template match="tei:docDate/tei:date" mode="meta">
    <xsl:variable name="notBefore" select="number(substring(@notBefore, 1, 4))"/>
    <xsl:variable name="notAfter" select="number(substring(@notAfter, 1, 4))"/>
    <xsl:variable name="when" select="number(substring(@when, 1, 4))"/>
    <xsl:choose>
      <xsl:when test="$when and not(@scope)">
        <meta name="start" content="{$when}"/>
        <meta name="end" content="{$when}"/>
      </xsl:when>
      <xsl:when test="$when and @scope">
        <meta name="start" content="{$when - $circa}"/>
        <meta name="end" content="{$when + $circa}"/>
      </xsl:when>
      <xsl:when test="@notBefore and @notBefore=@notAfter">
        <meta name="start" content="{$notBefore - 1}"/>
        <meta name="end" content="{$notAfter + 1}"/>
      </xsl:when>
      <xsl:when test="$notBefore and $notAfter">
        <meta name="start" content="{$notBefore}"/>
        <meta name="end" content="{$notAfter}"/>
      </xsl:when>
      <xsl:when test="$notBefore">
        <meta name="start" content="{$notBefore}"/>
        <meta name="end" content="{$notBefore + $antepost}"/>
      </xsl:when>
      <xsl:when test="$notAfter">
        <meta name="start" content="{$notAfter - $antepost}"/>
        <meta name="end" content="{$notAfter}"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:transform>
