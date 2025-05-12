<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform
  version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  exclude-result-prefixes="xsl rng"
>
  <!-- common imports -->
  <!--
  <xsl:include href="xrem.xsl"/>
  -->
  <xsl:output indent="no" method="xml" encoding="UTF-8" cdata-section-elements="cdata"/>
  <!-- donner une classe aux éléments pour que puisse s'y appliquer du stylage -->
  <xsl:param name="el-css"/>
  <xsl:param name="pre" select="false()"/>
  <!--
not used, but could be interesting to show content in <![CDATA[ declaration ]]>
especially for script where no chars should be expected
  -->
  <xsl:param name="cdatas" select="concat(' cdata ', normalize-space(/*/*/@cdata-section-elements), ' ')"/>
  <!-- elements with preformated content -->
  <xsl:param name="pres" select="' style script litterallayout pre logic '"/>
  <!-- pattern for xml entities -->
  <xsl:variable name="xmlents">&amp;:&amp;amp;,&gt;:&amp;gt;,&lt;:&amp;lt;</xsl:variable>


  <!--

namespace documentation URI


-->
  <!-- write an xml element name, use that to provide linking -->
  <xsl:template match="* | @*" name="xml_name" mode="xml_name" priority="-1">
    <b>
      <xsl:attribute name="class">
        <xsl:choose>
          <!-- namespace prefix as a CSS class -->
          <xsl:when test="contains(name(), ':')">
            <xsl:value-of select="substring-before(name(), ':')"/>
            <xsl:text> </xsl:text>
          </xsl:when>
          <!-- namespace of parent element for an att -->
          <xsl:when test="not(self::*) and contains(name(..), ':')">
            <xsl:value-of select="substring-before(name(..), ':')"/>
            <xsl:text> </xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:choose>
          <!-- if it's an element cf <http://www.dpawson.co.uk/xsl/sect2/nodetest.html#d8255e252> -->
          <xsl:when test="self::*">el</xsl:when>
          <xsl:otherwise>att</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="name()"/>
    </b>
  </xsl:template>

  <!-- link Dublin Core to its doc -->
  <xsl:template match="*[namespace-uri()='http://purl.org/dc/elements/1.1/']
|@*[namespace-uri()='http://purl.org/dc/elements/1.1/']
  " mode="xml_name">
    <a class="dc" href="http://dublincore.org/documents/dces/#{local-name()}">
      <xsl:value-of select="name()"/>
    </a>
  </xsl:template>
  <!-- link XSL elements to their doc -->
  <xsl:template match="*[namespace-uri()='http://www.w3.org/1999/XSL/Transform']" mode="xml_name">
    <a class="xsl" href="http://www.w3.org/TR/xslt#element-{local-name()}">
      <xsl:value-of select="name()"/>
    </a>
  </xsl:template>
  <!-- @href as link -->
  <xsl:template match="@href" mode="xml_value">
    <a href="{.}" class="val">
      <xsl:value-of select="."/>
    </a>
  </xsl:template>


  <!-- template to call from everywhere with a nodeset compatible processor -->
  <xsl:template name="xml2html">
    <xsl:param name="xml" select="."/>
    <xsl:apply-templates select="$xml" mode="xml2html"/>
  </xsl:template>
  <!-- this script is directly put in clicable elements, easier than a script to embed, but more expensive -->
  <xsl:template name="xml_click">
    <xsl:attribute name="onclick">
var id=(this.id)?this.id:this.name;
if (!id) return true; if (!document.getElementById) return true;
var o=document.getElementById(id+'-'); if (!o || !o.style) return true;
o.style.display=(o.style.display == 'none')?'':'none'; return false;
    </xsl:attribute>
  </xsl:template>
  <!-- PI -->
  <xsl:template match="processing-instruction()" mode="xml2html">
    <xsl:choose>
      <!-- 
<?img img/9782600403474_1_fausseTable.png ?>
<img src="img/9782600403474_1_fausseTable.png"/>
      -->
      <xsl:when test="name() = 'img'">
        <img src="{normalize-space(.)}"/>
      </xsl:when>
      <xsl:otherwise>
        <span class="pi">
          <xsl:text>&lt;?</xsl:text>
          <xsl:value-of select="name()"/>
          <xsl:value-of select="' '"/>
          <xsl:choose>
            <xsl:when test="contains(., ' href=&quot;')">
              <xsl:value-of select="substring-before(.,' href=&quot;')"/>
              <xsl:text> href="</xsl:text>
              <a>
                <xsl:attribute name="href">
                  <xsl:value-of select="substring-before(substring-after(.,' href=&quot;'), '&quot;')"/>
                </xsl:attribute>
                <xsl:value-of select="substring-before(substring-after(.,' href=&quot;'), '&quot;')"/>
              </a>
              <xsl:text>"</xsl:text>
              <xsl:value-of select="substring-after(substring-after(.,' href=&quot;'), '&quot;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="."/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>?&gt;</xsl:text>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- add xmlns declarations, probably better only for the root -->
  <xsl:template match="*|@*" name="xml_ns" mode="xml_ns">
    <xsl:param name="uris"/>
    <xsl:choose>
      <!-- for xsl conformant processor but not firefox -->
      <xsl:when test="namespace::*">
        <xsl:variable name="ns" select="../namespace::*"/>
        <xsl:for-each select="namespace::*">
          <xsl:if test="
                name() != 'xml'
                and (
                    not(. = $ns)
                    or not($ns[name()=name(current())])
                )">
            <div class="xmlns">
              <xsl:value-of select="' '"/>
              <span class="att">
                <xsl:text>xmlns</xsl:text>
                <xsl:if test="normalize-space(name())!=''">
                  <xsl:text>:</xsl:text>
                  <span class="ns">
                    <xsl:value-of select="name()"/>
                  </span>
                </xsl:if>
              </span>
              <xsl:text>="</xsl:text>
              <xsl:if test=". != ''">
                <code class="val">
                  <xsl:value-of select="."/>
                </code>
              </xsl:if>
              <xsl:text>"</xsl:text>
            </div>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <!-- for firefox (uncomplete) -->
      <xsl:when test="not(ancestor::*) or $uris != ''">
        <xsl:variable name="namespaces" select="concat($uris, ' ', namespace-uri() )"/>
        <div>
          <span class="att">
            <xsl:text>xmlns</xsl:text>
            <xsl:if test="name() != local-name()">
              <xsl:text>:</xsl:text>
              <span class="ns">
                <xsl:value-of select="substring-before(name(), ':')"/>
              </span>
            </xsl:if>
          </span>
          <xsl:text>="</xsl:text>
          <code class="val">
            <xsl:value-of select="namespace-uri()"/>
          </code>
          <xsl:text>"</xsl:text>
        </div>
        <xsl:apply-templates mode="xml_ns" select="
    (//*|//@*)[namespace-uri() != '']
                       [not( contains($namespaces, concat(' ', namespace-uri()) ) ) ]
                       [1]
        ">
          <xsl:with-param name="uris" select="$namespaces"/>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
    <!--
    <xsl:for-each select="namespace::*">

  could be nice, but seems to not work with firefox
-->
  </xsl:template>
  <xsl:template name="xmlns">

  </xsl:template>
  <!-- matching attribute -->
  <xsl:template match="@*" mode="xml2html">
    <!-- try to get an uri for this attribute name -->
    <xsl:value-of select="' '"/>
    <xsl:apply-templates select="." mode="xml_name"/>
    <xsl:text>=&quot;</xsl:text>
    <xsl:apply-templates select="." mode="xml_value"/>
    <xsl:text>"</xsl:text>
  </xsl:template>
  <!-- matching attribute value, may be overided -->
  <xsl:template match="@*" mode="xml_value">
    <!-- value of an attribute should be inline,
except the case of very long values where a preformatted block is more readable -->
    <xsl:choose>
      <xsl:when test="contains(., '&#10;') or contains(., '&#13;')">
        <pre class="val"><xsl:call-template name="xml_value"/></pre>
      </xsl:when>
      <xsl:when test="string-length(normalize-space(.)) &gt; 50">
        <div class="val">
          <xsl:call-template name="xml_value"/>
        </div>
      </xsl:when>
      <xsl:when test=". =''"/>
      <xsl:otherwise>
        <code class="val">
          <xsl:call-template name="xml_value"/>
        </code>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- provide the value of an attribute, with some text escaping -->
  <xsl:template name="xml_value">
    <xsl:param name="text" select="."/>
    <!--
    <xsl:variable name="br">
      <br/>
    </xsl:variable>
    <xsl:variable name="value">
       <xsl:choose>
        <xsl:when test="contains(., '&#10;')">

        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      -->
    <xsl:choose>
      <xsl:when test="
                    (contains(., '&amp;')
                    or contains(., '&lt;')
                    or contains(., '&gt;')
                    or contains(., '&quot;'))
                    ">
        <xsl:call-template name="xml_replace">
          <xsl:with-param name="text" select="."/>
          <xsl:with-param name="pattern" select="concat($xmlents, '&quot;:&amp;quot')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--  text -->
  <!--
    <xsl:template match="text()[normalize-space(.)='']" mode="xml2html">
    </xsl:template>
    ? -->
  <xsl:template match="text()" mode="xml2html">
    <xsl:param name="text" select="."/>
      <xsl:choose>
        <xsl:when test="
                    contains(., '&amp;')
                    or contains(., '&lt;')
                    or contains(., '&gt;')
        ">
          <span class="text">
            <xsl:call-template name="xml_replace">
              <xsl:with-param name="text" select="$text"/>
              <xsl:with-param name="pattern" select="$xmlents"/>
            </xsl:call-template>
          </span>
        </xsl:when>
        <xsl:when test="normalize-space(.)=''">
          <xsl:value-of select="."/>
        </xsl:when>
        <xsl:otherwise>
          <span class="text">
            <xsl:value-of select="."/>
          </span>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>
  <!--
comment
to override if you want comments to be html formatted if
you have some text_html.xsl
 -->
  <xsl:template match="comment()" mode="xml2html">
    <xsl:choose>
      <!-- A bloc comment -->
      <xsl:when test="contains(., '&#10;' ) or contains(., '&#13;')">
        <pre class="comment">
          <a tabindex="1" class="fold">
            <xsl:text>&lt;--</xsl:text>
          </a>
          <xsl:value-of select="." disable-output-escaping="yes"/>
          <a>--&gt;</a>
        </pre>
      </xsl:when>
      <xsl:otherwise>
        <div class="comment">
          <xsl:text>&lt;!--</xsl:text>
            <code>
              <xsl:value-of select="."/>
            </code>
          <xsl:text>--&gt;</xsl:text>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- mode id

Default naming of nodes for linking to source.
The default generate-id() of the XSL engine
We can imagine an xpath id generator, or some
nicer rule depending on the namespace.

-->
  <xsl:template match="node()|@*" mode="xml_id">
    <xsl:value-of select="generate-id()"/>
  </xsl:template>
  <!--

handling elements

  -->
  <xsl:template match="*" name="xml_element" mode="xml2html">
    <!-- this param is not used here but passed to xml_content template
that an importer could override -->
    <xsl:param name="mode"/>
    <xsl:param name="id">
      <xsl:apply-templates select="." mode="xml_id"/>
    </xsl:param>
    <xsl:param name="inline" select="../text()[normalize-space(.)!='']"/>
    <xsl:param name="content" select="
text()[normalize-space(.)!='']
| comment() | processing-instruction() | *"/>
    <xsl:param name="name" select="local-name()"/>
    <!-- un code de classe pour le conteneur -->
    <xsl:param name="class">
      <xsl:if test="$el-css">
        <xsl:value-of select="translate(name(), ':', '_')"/>
        <xsl:if test="ancestor::rng:element[1]/@name = $name"> hilite</xsl:if>
      </xsl:if>
    </xsl:param>
    <xsl:choose>
      <!-- empty inline -->
      <xsl:when test="$inline and not($content)">
        <!-- has a break line effect -->
        <xsl:if test="$name = 'lb'"><br/></xsl:if>
        <span class="open {$class}">
          <xsl:text>&lt;</xsl:text>
          <xsl:apply-templates select="." mode="xml_name"/>
          <!-- TOTEST -->
          <xsl:call-template name="xml_ns"/>
          <xsl:apply-templates select="@*" mode="xml2html"/>
          <xsl:text>/&gt;</xsl:text>
        </span>
      </xsl:when>
      <!-- empty block -->
      <xsl:when test="not($content)">
        <div class="open {$class}">
          <xsl:text>&lt;</xsl:text>
          <xsl:apply-templates select="." mode="xml_name"/>
          <!-- TOTEST -->
          <xsl:call-template name="xml_ns"/>
          <xsl:apply-templates select="@*" mode="xml2html"/>
          <xsl:text>/&gt;</xsl:text>
        </div>
      </xsl:when>
      <!-- inline -->
      <xsl:when test="$inline">
        <span class="{$class}">
          <span class="open">
            <xsl:text>&lt;</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <!-- TOTEST -->
            <xsl:call-template name="xml_ns"/>
            <xsl:apply-templates select="@*" mode="xml2html"/>
            <xsl:text>&gt;</xsl:text>
          </span>
          <xsl:call-template name="xml_content">
            <xsl:with-param name="inline" select="true()"/>
            <xsl:with-param name="mode" select="$mode"/>
          </xsl:call-template>
          <span class="close">
            <xsl:text>&lt;/</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </span>
        </span>
      </xsl:when>
      <!-- preformated element, if listed in $pre and no children (text only) -->
      <xsl:when test="
(@xml:space='preserve' or contains($pres, concat(' ', local-name(), ' ')))
">
        <xsl:variable name="element">
          <xsl:choose>
            <xsl:when test="contains(., '&#10;')">pre</xsl:when>
            <xsl:otherwise>div</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$element}" namespace="http://www.w3.org/1999/xhtml">
          <xsl:attribute name="class">pre <xsl:value-of select="$class"/></xsl:attribute>
          <span class="open">
            <a class="fold" tabindex="1">
              <xsl:text>&lt;</xsl:text>
            </a>
            <xsl:apply-templates select="." mode="xml_name"/>
            <!-- TOTEST -->
            <xsl:call-template name="xml_ns"/>
            <xsl:apply-templates select="@*" mode="xml2html"/>
            <xsl:text>&gt;</xsl:text>
          </span>
          <code>
            <xsl:call-template name="xml_content">
              <xsl:with-param name="inline" select="true()"/>
              <xsl:with-param name="mode" select="$mode"/>
            </xsl:call-template>
          </code>
          <span class="close">
            <xsl:text>&lt;/</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </span>
        </xsl:element>
      </xsl:when>
      <!-- mixed block -->
      <xsl:when test="text()[normalize-space(.)!=''] and *">
        <div class="xml_block {$class}">
          <span class="open">
            <a class="fold" tabindex="1">
              <xsl:text>&lt;</xsl:text>
            </a>
            <xsl:apply-templates select="." mode="xml_name"/>
            <!-- TOTEST -->
            <xsl:call-template name="xml_ns"/>
            <xsl:apply-templates select="@*" mode="xml2html"/>
            <xsl:text>&gt;</xsl:text>
          </span>
          <span class="xml_mix">
            <xsl:call-template name="xml_content">
              <xsl:with-param name="inline" select="true()"/>
              <xsl:with-param name="mode" select="$mode"/>
            </xsl:call-template>
          </span>
          <span class="close">
            <xsl:text>&lt;/</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </span>
        </div>
      </xsl:when>
      <!-- structured block with indent -->
      <xsl:when test="normalize-space(text()) = '' and *">
        <dl class="xml {$class}">
          <dt class="open">
            <a class="fold" tabindex="1">
              <xsl:text>&lt;</xsl:text>
            </a>
            <xsl:apply-templates select="." mode="xml_name"/>
            <!-- TOTEST -->
            <xsl:call-template name="xml_ns"/>
            <xsl:apply-templates select="@*" mode="xml2html"/>
            <xsl:text>&gt;</xsl:text>
          </dt>
          <dd class="code">
            <xsl:call-template name="xml_content">
              <xsl:with-param name="mode" select="$mode"/>
            </xsl:call-template>
          </dd>
          <dt class="close">
            <xsl:text>&lt;/</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </dt>
        </dl>
      </xsl:when>
      <!-- block or with no children -->
      <xsl:otherwise>
        <div class="{$class}">
          <span class="open">
            <xsl:text>&lt;</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <!-- TOTEST -->
            <xsl:call-template name="xml_ns"/>
            <xsl:apply-templates select="@*" mode="xml2html"/>
            <xsl:text>&gt;</xsl:text>
          </span>
          <xsl:call-template name="xml_content">
            <xsl:with-param name="mode" select="$mode"/>
          </xsl:call-template>
          <span class="close">
            <xsl:text>&lt;/</xsl:text>
            <xsl:apply-templates select="." mode="xml_name"/>
            <xsl:text>&gt;</xsl:text>
          </span>
        </div>
      </xsl:otherwise>
    </xsl:choose>
    <!-- MAYDO
    <xsl:if test="$hide">
        <xsl:attribute name="style">display:none; {};</xsl:attribute>
    </xsl:if>
    <xsl:if test="$cdata and $content">
        <xsl:text>&lt;![CDATA[</xsl:text>
    </xsl:if>

    <xsl:if test="$cdata">
        <xsl:text>]]&gt;</xsl:text>
    </xsl:if>

-->
  </xsl:template>
  <!--
Generate what is inside an element.
This template is isolated if importer wants to override
-->
  <xsl:template name="xml_content">
    <xsl:param name="inline"/>
    <xsl:apply-templates select="node()" mode="xml2html">
      <xsl:with-param name="inline" select="$inline"/>
    </xsl:apply-templates>
  </xsl:template>
  <!-- unplugged because of possible infinite loop -->
  <!--
    <xsl:template match="*[local-name()='include' or local-name()='import']" mode="xml2html">
        <xsl:call-template name="xml_name">
            <xsl:with-param name="element" select="."/>
            <xsl:with-param name="content" select="document(@href, .)"/>
            <xsl:with-param name="hide" select="true()"/>
        </xsl:call-template>
    </xsl:template>
    -->
  <!--
a not too less efficient multiple search/replace
pass a string like "find:replace, search:change ..."
if you want to search/replace ':' or ',', do a "translate()" before using this pattern

thanks to jeni@jenitennison.com for its really clever recursive template
http://www.biglist.com/lists/xsl-list/archives/200110/msg01229.html
But is replacing nodeset by functions a good XSL practice ?
String functions seems more useful.

TOTEST &#xA;:<br/> (may work with a <xsl:param select="//br"/>)


  -->
  <xsl:template name="xml_replace">
    <!-- the text to parse -->
    <xsl:param name="text"/>
    <!--
a pattern in form
"find:replace,?:!,should disapear:, significant spaces  :SignificantSpaces"
default is for XML entities
-->
    <xsl:param name="pattern" select="$xmlents"/>
    <!-- current simple string to find -->
    <xsl:param name="find" select="substring-before($pattern, ':')"/>
    <!-- current simple string to replace -->
    <xsl:param name="replace" select="substring-after(substring-before($pattern, ','), ':')"/>
    <xsl:choose>
      <!-- perhaps unuseful, I don't know -->
      <xsl:when test="$text=''"/>
      <!-- nothing to do, output and exit -->
      <xsl:when test="normalize-space($pattern)=''">
        <xsl:copy-of select="$text"/>
      </xsl:when>
      <!-- normalize pattern for less tests (last char is a comma ',') -->
      <xsl:when test="substring($pattern, string-length($pattern)) != ','">
        <xsl:call-template name="xml_replace">
          <xsl:with-param name="text" select="$text"/>
          <xsl:with-param name="pattern" select="concat( $pattern, ',')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$find != '' and contains($text, $find)">
        <!-- search before with reduced pattern -->
        <xsl:call-template name="xml_replace">
          <xsl:with-param name="text" select="substring-before($text, $find)"/>
          <xsl:with-param name="pattern" select="substring-after($pattern, ',')"/>
        </xsl:call-template>
        <!-- copy-of current replace -->
        <xsl:copy-of select="$replace"/>
        <!-- search after with complete pattern -->
        <xsl:call-template name="xml_replace">
          <xsl:with-param name="text" select="substring-after($text, $find)"/>
          <xsl:with-param name="pattern" select="$pattern"/>
        </xsl:call-template>
      </xsl:when>
      <!-- current find not found, continue for another -->
      <xsl:when test="substring-after($pattern, ',')!=''">
        <xsl:call-template name="xml_replace">
          <xsl:with-param name="text" select="$text"/>
          <xsl:with-param name="pattern" select="substring-after($pattern, ',')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- infinite loop or something forgotten ? -->
      <xsl:otherwise>
        <xsl:copy-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:transform>
