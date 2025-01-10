<?xml version="1.0" encoding="UTF-8"?>
<!--
Cette transformation a surtout besoin d'être rapide,
pour que l'utilisateur puisse la recharger facilement et souvent
dans le navigateur.

Ce n'est pas la copie de la diffusion finale.
-->
<xsl:transform
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:h="http://www.tei-c.org/ns/1.0"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt"
  xmlns:str="http://exslt.org/strings"
  xmlns:saxon="http://icl.com/saxon"
  xmlns:exslt="http://exslt.org/common"
version="1.1" extension-element-prefixes="str saxon msxsl exslt">
  <!-- nom de fichier -->
  <xsl:param name="nom"/>
  <!-- base pour les liens -->
  <xsl:param name="site" select="'http://ducange.enc.sorbonne.fr/2009/htm/'"/>
  <!-- target des liens du rapport -->
  <xsl:param name="target" select="'article'"/>
  <!-- extension des fichiers de rapport -->
  <xsl:param name="ext" select="'.htm'"/>
  <!-- rapport personnalisé -->
  <xsl:param name="qui"/>
  <xsl:output indent="yes" method="xml" encoding="UTF-8"/>

  <xsl:template match="/">
  <!--
    <xsl:text disable-output-escaping="yes"><![CDATA[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
]]></xsl:text>
-->
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <title><xsl:value-of select="$nom"/>, rapport d'erreurs</title>
        <link rel="stylesheet" type="text/css" href="rapport.css"/>
        <!-- script type="text/javascript" src="edit.js">//</script -->
      </head>
      <body>
        <xsl:if test="document('_dir.tmp', .)">
          <xsl:for-each select="document('_dir.tmp', .)/*/*">
            <xsl:sort select="."/>
            <xsl:text> | </xsl:text>
            <a href="{.}.htm">
              <xsl:value-of select="."/>
            </a>
          </xsl:for-each>
          <xsl:text> | </xsl:text>
        </xsl:if>
        <h1><xsl:value-of select="$nom"/>.xml</h1>
        <!--
        <script type="text/javascript">
var file="<xsl:value-of select="$file"/>";
<xsl:text disable-output-escaping="yes"><![CDATA[
var noframe;
// donner le lien pour replacer la page dans un frame
if (window.top == window) {
  noframe=true;
  var uri=window.location.href;
  var pathsep=(uri.indexOf("\\"))?"\\":"/";
  uri=uri.substring(0, uri.lastIndexOf(pathsep)) + "index.htm?rapport="+file;
  document.write('<a href="index.htm?rapport='+file+'">Cadres</a>');
}
]]></xsl:text>
         </script>
        -->
<!--
          <form action="">
          <select onchange="if (! this.selectedIndex) return;
  this.form.action=this.options[this.selectedIndex].text + '{$ext}';
  this.form.submit();
          ">
            <option/>
            <xsl:call-template name="options">
              <xsl:with-param name="csv">A,B,C,D,E,F,G,H,I,K,L,M,N,O,P,Q,R,S,T,V,W,X,Y,Z</xsl:with-param>
              <xsl:with-param name="selected" select="$lettre"/>
            </xsl:call-template>
          </select>
          l.
          <input name="clipboard" size="5" style="border:none" id="clipboard" accesskey="C" onfocus="this.select()"/>
          <input type="submit" value="recharger"/>
        </form>
        <form  action="http://ducange.enc.sorbonne.fr/2009/nomenclature.php" target="image">
          Nomenclature<br/>
          <input type="hidden" name="f" value="prefixe"/>
          <input name="q"/>
          <input type="submit" value="&gt;"/>
        </form>
        -->
        <xsl:choose>
          <xsl:when test="contains($qui, 'elise')">
            <xsl:call-template name="elise"/>
          </xsl:when>
          <xsl:when test="contains($qui, 'frederic')">
            <xsl:call-template name="frederic"/>
          </xsl:when>
        </xsl:choose>
        <!--
        <div id="gauche" style="overflow:auto; height:100%; width:25%; float:left;">
          <xsl:call-template name="rapport"/>
        </div>
        <div id="centre" style="overflow:auto; height:100%; width:50%; float:left;">
          <xsl:apply-templates/>
        </div>
        <div id="droite" style="overflow:auto; height:100%;  width:316px; float:left;">
          <img src="../theme/fermer.png" style="position:fixed; _position:absolute;  right:2px; top:2px; cursor:hand; cursor:pointer;" onclick="this.parentNode.style.display='none';dim()"/>
          <img id="col-img" width="300" src="../jpg/X/419b.jpg">
            <xsl:attribute name="src">
              <xsl:value-of select="$context"/>
              <xsl:text>jpg/</xsl:text>
              <xsl:value-of select="$lettre"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="//pb/@n"/>
              <xsl:text>b.jpg</xsl:text>
            </xsl:attribute>
          </img>
        </div>
        <iframe id="droite" width="316px" height="100%" marginheight="0" name="image" marginwidth="0" style="float:right" border="0">
            <xsl:attribute name="src">
              <xsl:value-of select="$context"/>
              <xsl:text>jpg/</xsl:text>
              <xsl:value-of select="$lettre"/>
              <xsl:text>/</xsl:text>
              <xsl:value-of select="//pb/@n"/>
              <xsl:text>b.jpg</xsl:text>
            </xsl:attribute>
        </iframe>
        -->
      </body>
    </html>
  </xsl:template>

  <!-- Rapport pour Elise -->
  <xsl:template name="elise">
    <div id="rapport">
      <div id="titre">Rapport pour Elise</div>
      <xsl:call-template name="lang"/>
      <xsl:call-template name="date"/>
    </div>
  </xsl:template>


  <!-- Rapport pour Frédéric -->
  <xsl:template name="frederic">
    <div id="rapport">
      <h4>Noms propres</h4>
      <pre>
      <xsl:choose>
        <xsl:when test="function-available('exslt:node-set')">
          <xsl:variable name="ENs">
            <xsl:for-each select="//h:div[@type='transcription']">
              <xsl:copy-of select=".//h:name | .//h:persName | .//h:placeName"/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:for-each select="exslt:node-set($ENs)/*">
            <xsl:sort select="."/>
            <xsl:apply-templates select="." mode="xml"/>
            <xsl:text>
</xsl:text>
          </xsl:for-each>
        </xsl:when>
        <!--
        <xsl:when test="function-avaliable('msxsl:node-set')">
          <xsl:apply-templates select="msxsl:node-set($nodelist)" />
        </xsl:when>
        -->
        <xsl:otherwise>
          <xsl:for-each select="//h:div[@type='transcription']//h:name | //h:div[@type='transcription']//h:placeName | //h:div[@type='transcription']//h:persName">
            <xsl:sort/>
            <xsl:apply-templates select="." mode="xml"/>
            <xsl:text>,
</xsl:text>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      </pre>
    </div>
  </xsl:template>

  <!-- Liste des actes sans indications de langues -->
  <xsl:template name="lang">
    <xsl:variable  name="nodeset" select="//h:div[@type='transcription'][not(@xml:lang) or @xml:lang='xx']"/>
    <xsl:if test="$nodeset">
      <p><b>Langue</b> -
          <xsl:value-of select="count($nodeset)"/> actes sans indications de langue<br/>
          <xsl:call-template name="liens">
            <xsl:with-param name="nodeset" select="$nodeset"/>
          </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>

  <!-- Liste des actes sans indications de date -->
  <xsl:template name="date">
    <h4>Dates</h4>
    <xsl:variable  name="nodes" select="//h:text[@xml:id][not(h:front/h:docDate/h:date)]"/>
    <xsl:if test="$nodes">
      <p><xsl:value-of select="count($nodes)"/> actes sans élément date<br/>
        <xsl:for-each select="$nodes">
          <xsl:text>xml:id="</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>" </xsl:text>
          <br/>
        </xsl:for-each>
      </p>
    </xsl:if>
    <xsl:variable  name="nodeset" select="//h:docDate/h:date[not(@when) and not(@notAfter) and not(@notBefore)]"/>
    <xsl:if test="$nodeset">
      <p>
        <xsl:value-of select="count($nodeset)"/> actes avec encodage de date à vérifier<br/>
        <xsl:for-each select="$nodeset">
          <xsl:text>xml:id="</xsl:text>
          <xsl:value-of select="ancestor::*[@xml:id][1]/@xml:id"/>
          <xsl:text>" </xsl:text>
          <xsl:apply-templates select="." mode="xml"/>
          <br/>
        </xsl:for-each>
        <!--
        <xsl:call-template name="liens">
          <xsl:with-param name="nodeset" select="$nodeset"/>
        </xsl:call-template>
        -->
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template name="unclear">
    <xsl:param name="doc" select="/"/>
    <xsl:param name="prefix"><b>&lt;unclear></b></xsl:param>
    <xsl:variable  name="nodeset" select="$doc//unclear"/>
    <xsl:if test="$nodeset">
      <p id="unclear">
        <xsl:copy-of select="$prefix"/>
          <xsl:value-of select="count($nodeset)"/> &lt;unclear> signalés par le prestataire, à corriger.<br/>
          <xsl:call-template name="liens">
            <xsl:with-param name="nodeset" select="$nodeset"/>
          </xsl:call-template>
      </p>
    </xsl:if>
    <!--
          <a href="http://en.wikipedia.org/wiki/Thorn_(letter)" target="{$target}" onclick="clipboard('þ')">þ</a>
          <a href="http://en.wikipedia.org/wiki/%C3%90" target="{$target}" onclick="clipboard('ð')">ð</a><br/>
      -->
  </xsl:template>

  <xsl:template name="smallfont">
    <xsl:variable  name="nodeset" select="//hi[@rend='smallfont']"/>
    <xsl:if test="$nodeset">
      <p><b>smallfont </b>
          <xsl:value-of select="count($nodeset)"/> citations mal intéreprétées.<br/>
          <xsl:call-template name="liens">
            <xsl:with-param name="nodeset" select="$nodeset"/>
          </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>


  <xsl:template name="doutes">
    <xsl:variable name="doute" select="//comment()[starts-with(normalize-space(.), 'DOUTE')]"/>
    <xsl:if test="$doute">
      <p id="doutes"><b>Doutes</b><xsl:text> signalés par le prestataire, à corriger.</xsl:text>
          <xsl:value-of select="count($doute)"/><br/>
          <xsl:call-template name="liens">
            <xsl:with-param name="nodeset" select="$doute"/>
          </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template name="homographes">
    <xsl:variable  name="homographes" select="//form[@type != 1][string-length(normalize-space(.)) != string-length(translate(normalize-space(.), '0123456789', ''))]"/>
    <xsl:if test="$homographes">
      <p id="homographes"><b>Homographes perdus</b><xsl:text> </xsl:text>
          <xsl:value-of select="count($homographes)"/> :
          <xsl:call-template name="liens">
            <xsl:with-param name="nodeset" select="$homographes"/>
          </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template name="taille">
    <div><xsl:value-of select="count(//pb)"/> pages (<xsl:value-of select="//pb[not(preceding::pb)]/@n"/>-<xsl:value-of select="//pb[not(following::pb)]/@n"/>), <xsl:value-of select="string-length(normalize-space(/))"/> caractères, <xsl:value-of select="string-length(normalize-space(/)) - string-length(normalize-space(translate(/, ' ', '')))"/> mots. </div>
    <div><xsl:value-of select="count(//entry)"/> articles, <xsl:value-of select="count(//entry/dictScrap[1]/form)"/> vedettes, <xsl:value-of select="count(//dictScrap)"/> paragraphes.
      </div>
  </xsl:template>

  <xsl:template name="quote-space">
    <xsl:variable name="quote-space" select="//quote[(string-length(normalize-space(.)) - string-length(translate(normalize-space(.), ' ', ''))) &lt; 3]"/>
    <xsl:if test="$quote-space">
      <p id="quote-space"><b>
      <xsl:value-of select="count($quote-space)"/>
      citations courtes</b>, contenant moins de 2 espaces. Des mots en mention ? étrangers ? Il faut des vraies citations.
        <xsl:call-template name="liens">
          <xsl:with-param name="nodeset" select="$quote-space"/>
        </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>

  <xsl:template name="i-punct">
    <xsl:variable name="i-punct" select="//i[translate(., '.,:)]?!', '') != .]"/>
    <xsl:if test="$i-punct">
      <p id="i-punct"><b>
        <xsl:value-of select="count($i-punct)"/>
        segments italiques</b> contenant de la ponctuation, mauvais découpage ? citation ?
        <xsl:call-template name="liens">
          <xsl:with-param name="nodeset" select="$i-punct"/>
        </xsl:call-template>
      </p>
    </xsl:if>
  </xsl:template>


  <xsl:template name="options">
    <xsl:param name="csv"/>
    <xsl:param name="selected"/>
    <xsl:choose>
      <xsl:when test="normalize-space($csv) = ''"/>
      <xsl:otherwise>
        <xsl:variable name="text" select="normalize-space(substring-before(concat($csv, ','), ','))"/>
        <option>
          <xsl:if test="normalize-space($selected) = $text">
            <xsl:attribute name="selected">selected</xsl:attribute>
          </xsl:if>
          <xsl:value-of select="$text"/>
        </option>
        <xsl:call-template name="options">
          <xsl:with-param name="csv" select="substring-after($csv, ',')"/>
          <xsl:with-param name="selected" select="$selected"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="liens">
    <xsl:param name="nodeset"/>
    <xsl:for-each select="$nodeset">
      <!--
      <xsl:text> </xsl:text>
      <xsl:if test="true() or number($ligne) &gt; 0">
        <small>#<xsl:value-of select="$ligne"/></small>
      </xsl:if>
      -->
      <xsl:call-template name="link"/>
      <xsl:choose>
        <xsl:when test="position() = last()">.
</xsl:when>
        <xsl:otherwise>,
</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- une vue xml d'éléments -->
  <xsl:template match="*" mode="xml">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:apply-templates select="@*" mode="xml"/>
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="xml"/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>
  <!-- une vue xml d'attributs -->
  <xsl:template match="@*" mode="xml">
    <xsl:text> </xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>="</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
  </xsl:template>


  <!-- Modèle pour créer un lien vers l'acte concerné -->
  <xsl:template name="link">
    <xsl:param name="id" select="ancestor-or-self::h:text[1]/@xml:id"/>
    <xsl:variable name="l">
      <xsl:if test="function-available('saxon:line-number')">
        <xsl:value-of select="saxon:line-number()"/>
      </xsl:if>
    </xsl:variable>
    <a title="ligne {$l}">
      <xsl:value-of select="substring-after($id, '-')"/>
    </a>
  </xsl:template>

<!-- résolution de chemin vers une css -->
  <xsl:template name="pi-lien">
    <xsl:param name="pi" select="/processing-instruction('xml-stylesheet')"/>
    <xsl:choose>
      <xsl:when test="contains($pi, 'href=&quot;')">
        <xsl:call-template name="pi-lien">
          <xsl:with-param name="pi" select="substring-after($pi, 'href=&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pi, '&quot;')">
        <xsl:call-template name="pi-lien">
          <xsl:with-param name="pi" select="substring-before($pi, '&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pi, '\')">
        <xsl:call-template name="pi-lien">
          <xsl:with-param name="pi" select="translate($pi, '\', '/')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($pi, '/')">
        <xsl:value-of select="substring-before($pi, '/')"/>
        <xsl:text>/</xsl:text>
        <xsl:call-template name="pi-lien">
          <xsl:with-param name="pi" select="substring-after($pi, '/')"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


<!-- un peu de CSS par défaut -->
  <xsl:template name="style">
<!-- lien css résolu depuis une instruction xsl -->
    <xsl:if test="contains(/processing-instruction('xml-stylesheet'), 'xsl')">
      <link rel="stylesheet" type="text/css">
        <xsl:attribute name="href">
          <xsl:call-template name="pi-lien"/>
          <xsl:text>ducange.css</xsl:text>
        </xsl:attribute>
      </link>
    </xsl:if>
  </xsl:template>
</xsl:transform>
