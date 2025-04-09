<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei"
>
  <!-- Importer des dates -->
  <xsl:import href="common.xsl"/>
  <!-- Liste d'identifiants séparés d'espaces à ne pas procéder -->
  <xsl:param name="exclude"/>
  <!-- Liste d'identifiants séparés d'espaces à procéder -->
  <xsl:param name="include"/>
  <!-- Liste séparés d'espaces de “function” à sortir -->
  <xsl:param name="function"/>
  <xsl:key name="split" match="/" use="'root'"/>
  <!-- Key on structural items, do not use the keyword "split", or it will override the split key for 2site  -->
  <xsl:key name="div" match="*[descendant-or-self::*[starts-with(local-name(), 'div')][@type][contains(@type, 'article') or contains(@type, 'letter') or contains(@type, 'scene') or contains(@type, 'act') or contains(@type, 'chapter') or contains(@type, 'poem') or contains(@subtype, 'split')]] | tei:group/tei:text | tei:TEI/tei:text/tei:front/* | tei:TEI/tei:text/tei:back/* | tei:TEI/tei:text/tei:body/* " use="generate-id(.)"/>

  <xsl:variable name="who1">ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüý -’'</xsl:variable>
  <xsl:variable name="who2">abcdefghijklmnopqrstuvwxyzaaaaaaceeeeiiiinooooouuuuyaaaaaaceeeeiiiinooooouuuuy__</xsl:variable>
  <!-- Modes -->
  <xsl:variable name="txt">txt</xsl:variable>
  <xsl:variable name="iramuteq">iramuteq</xsl:variable>
  <xsl:variable name="lexico3">lexico3</xsl:variable>
  <xsl:variable name="castlist">castlist</xsl:variable>  
  <!-- Mode of text generation, used as a trigger for somes components, for example notes -->
  <xsl:param name="mode" select="$txt"/>
  <xsl:param name="lang"/>
  <!-- Nom de l'xslt appelante -->
  <xsl:variable name="this">tei2txt.xsl</xsl:variable>
  <!-- Clé sur les partie du discours -->
  <xsl:key name="function" match="*[@function]" use="@function"/>
  <xsl:key name="who" match="tei:sp" use="@who"/>
  <!-- Clé sur les personnages ? -->
  <xsl:output omit-xml-declaration="yes" encoding="UTF-8" method="text" indent="yes"/>
  <!-- Permet l'indentation des éléments de structure -->
  <xsl:strip-space elements="tei:TEI tei:TEI.2 tei:body tei:castList  tei:div tei:div1 tei:div2  tei:docDate tei:docImprint tei:docTitle tei:fileDesc tei:front tei:group tei:index tei:listWit tei:publicationStmp tei:publicationStmt tei:sourceDesc tei:SourceDesc tei:sources tei:text tei:teiHeader tei:text tei:titleStmt"/>
  <xsl:preserve-space elements="tei:l tei:p tei:s "/>
  <xsl:variable name="lf">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>
  <xsl:variable name="tab">
    <xsl:text>&#9;</xsl:text>
  </xsl:variable>
  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quot">"</xsl:variable>
  <xsl:template match="/">
    <xsl:apply-templates mode="txt"/>
  </xsl:template>
  <xsl:template match="*" mode="txt">
    <xsl:apply-templates mode="txt"/>
  </xsl:template>
  <xsl:template match="/*" mode="txt">
    <book>
      <xsl:if test="@xml:id and $mode = $lexico3">
        <xsl:text>&lt;book=</xsl:text>
        <xsl:value-of select="@xml:id"/>
        <xsl:text>&gt;</xsl:text>
        <xsl:value-of select="$lf"/>
      </xsl:if>
      <xsl:if test="$mode != $iramuteq">
        <xsl:call-template name="txt-fields"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$mode = $castlist">
          <xsl:for-each select="//tei:castList//tei:role/@xml:id">
            <xsl:call-template name="iratext"/>
            <xsl:text> *who_</xsl:text>
            <xsl:value-of select="."/>
            <xsl:value-of select="$lf"/>
            <xsl:for-each select="key('who', .)">
              <xsl:apply-templates mode="txt"/>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="txt"/>
          <xsl:variable name="notes">
            <xsl:apply-templates mode="txt-fn"/>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$mode = $iramuteq"/>
            <xsl:when test="$notes = ''"/>
            <xsl:otherwise>
    
    =========
    <xsl:copy-of select="$notes"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>
</xsl:text>
    </book>
  </xsl:template>
  <xsl:template name="txt-fields">
    <xsl:text>identifier: </xsl:text>
    <xsl:value-of select="$docid"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>creator: </xsl:text>
    <xsl:value-of select="$byline"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>date: </xsl:text>
    <xsl:value-of select="$docdate"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>title: </xsl:text>
    <xsl:value-of select="$doctitle"/>
    <xsl:value-of select="$lf"/>
  </xsl:template>
  <xsl:template match="node()" mode="txt-fn">
    <xsl:apply-templates mode="txt-fn"/>
  </xsl:template>
  <xsl:template match="tei:note" mode="txt-fn">
    <xsl:value-of select="$lf"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>[</xsl:text>
    <xsl:call-template name="n"/>
    <xsl:text>] </xsl:text>
    <xsl:apply-templates mode="txt"/>
  </xsl:template>
  <!-- éléments à arrêter -->
  <xsl:template match="tei:back | tei:front | tei:ref[not(node())] | tei:teiHeader" mode="txt"/>
  <xsl:template match="tei:figure" mode="txt"/>
  <xsl:template match="tei:bibl | tei:listBibl | tei:cit" mode="txt"/>
  <!-- Pour bulle, garder la biblio dans une note -->
  <xsl:template match="tei:note//tei:bibl | tei:note//tei:cit" mode="txt">
    <xsl:apply-templates mode="txt"/>
  </xsl:template> 
  <!-- dans les titres pour toc, arrêter : les notes, les sauts de page, de ligne de colonnes -->
  <xsl:template match="tei:cb | tei:fw | tei:g | tei:pb" mode="txt">
    <xsl:if test="translate(substring(following-sibling::node()[1], 1, 1), '  ,;.?!…:*$€', '') != ''">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>
  <!-- Traitement des notes -->
  <xsl:template match="tei:note" mode="txt">
    <xsl:choose>
      <!-- Note Paul -->
      <xsl:when test="@type='L'"/>
      <xsl:when test="$mode = 'iramuteq'"/>
      <xsl:otherwise>
        <xsl:text> [</xsl:text>
        <xsl:call-template name="n"/>
        <xsl:text>]</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="n">
    <xsl:choose>
      <xsl:when test="@n">
        <xsl:value-of select="@n"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:number level="any"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!-- Très spécifique -->
  <xsl:template match="tei:p[@ana='nota']" mode="txt"/>
  
  <xsl:template match="tei:quote" mode="txt">
    <xsl:choose>
      <xsl:when test="$mode = $iramuteq"/>
      <xsl:when test="ancestor::tei:p">
        <xsl:apply-templates mode="txt"/>
      </xsl:when>
      <xsl:when test="tei:p|tei:l">
        <xsl:value-of select="$lf"/>
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lf"/>
        <xsl:text>    </xsl:text>
        <xsl:apply-templates mode="txt"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template> 
  <!-- comportement par défaut sur les éléments, traverser -->
  <!-- Cas particulier -->
  <!-- acte -->
  <xsl:template match="tei:body[tei:div[@type='transcription']]" mode="txt">
    <xsl:apply-templates select="tei:div[@type='transcription']" mode="txt"/>
  </xsl:template>

  <!-- Permet la surcharge -->
  <xsl:template name="id-label">
    <xsl:variable name="id" select="ancestor-or-self::*[@xml:id][1]/@xml:id"/>
    <!-- sortir le préfixe de corpus quand c'est possible -->
    <xsl:variable name="strip" select="substring-after($id, /*/@xml:id)"/>
    <xsl:choose>
      <xsl:when test="$id =''">NOID</xsl:when>
      <xsl:when test="$strip = ''">
        <xsl:value-of select="$id"/>
      </xsl:when>
      <xsl:when test="starts-with($strip, '_')">
        <xsl:value-of select="substring($strip, 2)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$strip"/>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>

  <xsl:template match="tei:castList" mode="txt"/>
  <xsl:template match="tei:sp" mode="txt">
      <!-- iramuteq title -->
    <xsl:value-of select="$lf"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>****</xsl:text>
    <xsl:text> *who_</xsl:text>
    <xsl:choose>
      <xsl:when test="@who">
        <xsl:value-of select="translate(@who, $who1, $who2)"/>
      </xsl:when>
      <xsl:when test="tei:speaker">
        <xsl:value-of select="translate(tei:speaker, $who1, $who2)"/>
      </xsl:when>
    </xsl:choose>
    <xsl:if test="ancestor::*[2][@type and @type='act'][@n]">
      <xsl:text> *act_</xsl:text>
      <xsl:value-of select="../../@n"/>
    </xsl:if>
    <xsl:if test="parent::*[@type = 'scene'][@n]">
      <xsl:text> *scene_</xsl:text>
      <xsl:value-of select="../@n"/>
    </xsl:if>
    <xsl:if test="../*/@xml:id">
      <xsl:text> *id_</xsl:text>
      <xsl:value-of select="../*/@xml:id"/>
    </xsl:if>
    <xsl:value-of select="$lf"/>
    <xsl:apply-templates select="*" mode="txt"/>
  </xsl:template>
  <xsl:template match="tei:speaker" mode="txt"/>
  <xsl:template match="tei:stage" mode="txt">
    <!-- change behaviors on type of stage indication ?
     tei:sp/tei:stage | tei:div/tei:stage | tei:div2/tei:stage | tei:div1/tei:stage
    -->
  </xsl:template>
  <xsl:template match="tei:trailer"/>

<!-- 
<person xml:id="Valois-Madeleine">
                        <persName>Valois, Madeleine de</persName>
                        <birth>1520</birth>
                        <death>1537</death>
                        <event>
                            <p>fille de François I<hi rend="sup">er</hi>, avait épousé en janvier 1537 Jacques V (1512-1542), roi d'Écosse (1513-1542) ; elle mourut six mois plus tard, en juillet 1537.</p>
                        </event>
                    </person>
-->


  <!-- Ligne sans indentation -->
  <xsl:template match="tei:person | tei:event | tei:place" mode="txt">
    <xsl:apply-templates select="*" mode="txt"/>
  </xsl:template>
  <xsl:template match="tei:birth" mode="txt">
    <xsl:text> (</xsl:text>
    <xsl:apply-templates mode="txt"/>
    <xsl:text>–</xsl:text>
    <xsl:if test="not(following-sibling::tei:death)">–…) </xsl:if>
  </xsl:template>
  <xsl:template match="tei:death" mode="txt">
    <xsl:if test="not(preceding-sibling::tei:death)"> (…</xsl:if>
    <xsl:text>–</xsl:text>
    <xsl:apply-templates mode="txt"/>
    <xsl:text>) </xsl:text>
  </xsl:template>

  <!-- 
                          <place xml:id="Chevagnes">
                            <placeName>Chevagnes</placeName>
                            <location>
                                <district type="departement">allier</district>
                                <district type="arrondissement">Moulins</district>
                                <district type="canton">ch.-l. de cant.</district>
                            </location>
                        </place>
-->
  <xsl:template match="tei:location" mode="txt">
    <xsl:text> (</xsl:text>
    <xsl:for-each select="*">
      <xsl:if test="position() != 1">, </xsl:if>
      <xsl:apply-templates select="." mode="txt"/>
    </xsl:for-each>
    <xsl:text>) </xsl:text>
  </xsl:template>
  
 
    
  <!-- Verse, no division by sentence -->
  <xsl:template match="tei:l" mode="txt">
    <xsl:variable name="txt">
      <xsl:apply-templates mode="txt"/>
    </xsl:variable>
    <xsl:value-of select="$lf"/>
    <xsl:if test="@part = 'f' or @part = 'F' or @part = 'm' or @part = 'M' ">
      <xsl:text>      </xsl:text>
    </xsl:if>
    <xsl:value-of select="normalize-space($txt)"/>
    <!-- afficher n° vers ?
    <xsl:choose>
      <xsl:when test="@n and (@n mod 5 = 0)">
        <xsl:text>		</xsl:text>
        <xsl:value-of select="@n"/>
      </xsl:when>
    </xsl:choose>
    -->
  </xsl:template>
  <xsl:template match="tei:lg" mode="txt">
    <xsl:value-of select="$lf"/>
    <xsl:choose>
      <xsl:when test="$mode = 'null'">
        <xsl:variable name="lg">
          <xsl:for-each select="*">
            <xsl:if test="position() != 1"> / </xsl:if>
            <xsl:apply-templates select="." mode="txt"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="normalize-space($lg)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:byline" mode="txt">
    <xsl:variable name="txt">
      <xsl:apply-templates mode="txt"/>
    </xsl:variable>
    <xsl:value-of select="$lf"/>
    <xsl:value-of select="normalize-space($txt)"/>
    <xsl:copy-of select="$lf"/>
  </xsl:template>
  <xsl:template match="tei:p " mode="txt">
    <xsl:variable name="txt">
      <xsl:apply-templates mode="txt"/>
    </xsl:variable>
    <!-- Spacing ? -->
    <xsl:choose>
      <xsl:when test="ancestor::tei:note and position()=1"/>
      <xsl:when test="ancestor::tei:note">
        <xsl:value-of select="$lf"/>
        <xsl:text>    </xsl:text>
      </xsl:when>
      <xsl:when test="parent::tei:sp">
        <xsl:value-of select="$lf"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lf"/>
        <xsl:copy-of select="$lf"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="sent">
      <xsl:with-param name="txt" select="normalize-space($txt)"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="tei:lb" mode="txt">
    <xsl:value-of select="$lf"/>
  </xsl:template>

  <!-- Corpus lemmatisé -->
  <xsl:template match="tei:l[tei:w] | tei:p[tei:w]" mode="txt">
    <xsl:value-of select="$lf"/>
    <xsl:for-each select="*">
      <xsl:variable name="last" select="substring(preceding-sibling::tei:*[1], string-length(preceding-sibling::tei:*[1]))"/>
      <xsl:choose>
        <xsl:when test="position()=1"/>
        <xsl:when test=". = $apos or .=$quot"/>
        <!-- espace insécable pour ponctuation double -->
        <xsl:when test="substring-before('$;:!?»', .)"> </xsl:when>
        <!-- ponctuation simple -->
        <xsl:when test="substring-before('$...…,‘’()[]“”', .)"/>
        <xsl:when test="$last=$apos or $last=$quot or substring-before('$’  ', $last)"/>
        <xsl:when test="starts-with(., '-')"/>
        <xsl:otherwise>
          <xsl:text> </xsl:text>
        </xsl:otherwise>        
      </xsl:choose>
      <xsl:apply-templates mode="txt"/>
    </xsl:for-each>    
  </xsl:template>
  <!-- Mot de corpus lemmatisé -->
  <xsl:template match="tei:w | tei:c" mode="txt">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- Segments  -->
  <xsl:template match="tei:seg[@function]" mode="txt">
    <xsl:param name="function" select="$function"/>
    <xsl:choose>
      <xsl:when test="normalize-space($function) != '' and not(contains(concat(' ',normalize-space($function), ' '), concat(' ', @function, ' ')))">
        <!-- Procéder les enfants au cas où -->
        <xsl:apply-templates select="*[@function]" mode="txt"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="position() != 1">
          <xsl:value-of select="$lf"/>
        </xsl:if>
        <xsl:text>&lt;seg</xsl:text>
        <xsl:value-of select="count(ancestor-or-self::tei:seg[@function])"/>
        <xsl:text>=</xsl:text>
        <xsl:value-of select="@function"/>
        <xsl:variable name="id" select="ancestor::tei:text[@xml:id]/@xml:id"/>
        <xsl:text>_</xsl:text>
        <xsl:choose>
          <xsl:when test="/*/@xml:id  and starts-with($id, concat(/*/@xml:id, '_'))">
            <xsl:value-of select="substring-after($id, concat(/*/@xml:id, '_'))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$id"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&gt; </xsl:text>
        <xsl:for-each select="node()">
          <xsl:variable name="txt">
            <xsl:apply-templates select="." mode="txt">
              <xsl:with-param name="function"/>
            </xsl:apply-templates>     
          </xsl:variable>
          <xsl:if test="position() &gt; 1 and normalize-space($txt) != '' and self::tei:seg">
            <xsl:value-of select="$lf"/>
          </xsl:if>
          <xsl:value-of select="normalize-space($txt)"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:template>

  <!-- Sections, split candidates -->
  <xsl:template match="
    tei:body | tei:group |
    tei:div | tei:div0 | tei:div1 | tei:div2 | tei:div4 | tei:div5 | tei:div6 | tei:div7 
" mode="txt">
    <xsl:choose>
      <!-- section avec juste des notes -->
      <xsl:when test="not(tei:p | tei:div | tei:div1 | tei:div2 | tei:div3 | tei:quote | tei:l | tei:lg | tei:list)"/>
      <!-- Do not open a title for an empty parent section -->
      <xsl:when test="descendant::*[key('div', generate-id())]">
        <!--
        <xsl:variable name="before" select="generate-id( tei:group | tei:div | tei:div1 | tei:div2 | tei:div3 | tei:div4 | tei:div5 | tei:div6 )"/>
        <xsl:variable name="text">
          <xsl:apply-templates select="tei:*[following-sibling::*[generate-id(.)=$before]]" mode="txt"/>
        </xsl:variable>
        <xsl:if test="string-length($text) &gt; 100">
          <xsl:if test="$mode = $iramuteq">
            <xsl:call-template name="iratext"/>
          </xsl:if>
          <xsl:copy-of select="$text"/>
        </xsl:if>
        -->
        <!-- Process other children -->
        <xsl:apply-templates select="tei:group | tei:div | tei:div1 | tei:div2 | tei:div3 | tei:div4 | tei:div5 | tei:div6" mode="txt"/>
      </xsl:when>
      <!-- Should be last level to split -->
      <xsl:when test="key('div', generate-id())">
        <xsl:if test="$mode = $iramuteq">
          <xsl:call-template name="iratext"/>
        </xsl:if>
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- section -->
  <xsl:template match="TODO" mode="txt">
    <xsl:choose>
      <!-- identifiant exclus -->
      <xsl:when test="@xml:id!='' and $exclude!='' and contains(concat(' ', normalize-space($exclude), ' '), concat(' ', normalize-space(@xml:id), ' '))"/>
      <!-- identifiant non inclus -->
      <xsl:when test="@xml:id!='' and $include!='' and not(contains(concat(' ', normalize-space($include), ' '), concat(' ', normalize-space(@xml:id), ' ')))"/>
      <!-- langue demandée et absente  -->
      <xsl:when test="$lang and normalize-space($lang) != '' and ancestor-or-self::*[@xml:lang] and not(starts-with(ancestor-or-self::*[@xml:lang][1]/@xml:lang, $lang))"/>
      <!-- chapitre -->
      <xsl:when test="self::tei:group">
        <xsl:value-of select="$lf"/>
        <xsl:if test="@xml:id">
          <xsl:text>&lt;group=</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>&gt;</xsl:text>
          <xsl:value-of select="$lf"/>
        </xsl:if>
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:when>
      <!-- <text>, <group> -->
      <xsl:when test="not(self::tei:div) or $mode!='lexico3'">
        <xsl:apply-templates select="*" mode="txt"/>
      </xsl:when>
      <!-- Langue par défaut -->
      <xsl:otherwise>
        <xsl:variable name="meta">
          <xsl:value-of select="$lf"/>
          <xsl:value-of select="$lf"/>
          <xsl:text>  &lt;id=</xsl:text>
          <xsl:call-template name="id-label"/>
          <xsl:text>&gt;
  </xsl:text>
          <xsl:if test="@xml:lang">
            <xsl:text>  &lt;lang=</xsl:text>
            <xsl:value-of select="@xml:lang"/>
            <xsl:text>&gt;
  </xsl:text>
          </xsl:if>
          <xsl:if test="../../tei:front/tei:docDate">
            <xsl:text>  &lt;date=</xsl:text>
            <xsl:value-of select="
           substring(
              ../../tei:front/tei:docDate/tei:date/@notBefore
            | ../../tei:front/tei:docDate/tei:date/@when
           , 1, 4)
          "/>
            <xsl:text>&gt;</xsl:text>
            <xsl:value-of select="$lf"/>
          </xsl:if>
          <!-- à réfléchir -->
          <xsl:if test="../../tei:front/tei:head and not(tei:head)">
            <xsl:apply-templates select="../../tei:front/tei:head" mode="txt"/>
            <xsl:value-of select="$lf"/>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="txt">
          <xsl:apply-templates select="*" mode="txt"/>
        </xsl:variable>
        <xsl:if test="normalize-space($txt) != ''">
          <xsl:copy-of select="$meta"/>
          <xsl:copy-of select="$txt"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- iramuteq title -->
  <xsl:template name="iratext">
    <xsl:value-of select="$lf"/>
    <xsl:value-of select="$lf"/>
    <xsl:text>****</xsl:text>
    <xsl:text> *book_</xsl:text>
    <xsl:choose>
      <xsl:when test="/*/@xml:id">
        <xsl:value-of select="/*/@xml:id"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$filename"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> *id_</xsl:text>
    <xsl:call-template name="id"/>
    <xsl:variable name="created">
      <xsl:choose>
        <xsl:when test="tei:docDate">
          <xsl:apply-templates select="tei:docDate[1]" mode="year"/>
        </xsl:when>
        <xsl:when test="tei:dateline/tei:docDate">
          <xsl:apply-templates select="(tei:dateline/tei:docDate)[1]" mode="year"/>
        </xsl:when>
        <xsl:when test="tei:byline/tei:docDate">
          <xsl:apply-templates select="(tei:byline/tei:docDate)[1]" mode="year"/>
        </xsl:when>
        <xsl:when test="$docdate">
          <xsl:value-of select="$docdate"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$created != ''">
      <xsl:text> *date_</xsl:text>
      <xsl:value-of select="$created"/>
    </xsl:if>
    <xsl:variable name="creator">
      <xsl:variable name="key" select="/*/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author/@key"/>
      <xsl:choose>
        <xsl:when test="$key != ''">
          <xsl:value-of select="translate(normalize-space(substring-before(concat($key, ','), ',')), $who1, $who2)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$creator != ''">
      <xsl:text> *creator_</xsl:text>
      <xsl:value-of select="$creator"/>
    </xsl:if>
    <xsl:for-each select="tei:index[@indexName]">
      <xsl:text> *</xsl:text>
      <xsl:value-of select="translate(@indexName, $who1, $who2)"/>
      <xsl:text>_</xsl:text>
      <xsl:choose>
        <xsl:when test="@n">
          <xsl:value-of select="translate(@n, $who1, $who2)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="translate(., $who1, $who2)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="tei:div[@type='letter']/tei:head" mode="txt"/>
  <xsl:template match="tei:head" mode="txt">
    <xsl:variable name="level" select="count(ancestor::*[tei:head])"/>
    <xsl:variable name="text">
      <xsl:apply-templates mode="txt"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="../@type = 'scene' or ../@type = 'act'"/>
      <xsl:when test="$mode = 'iramuteq'">
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="normalize-space($text)"/>
      </xsl:when>
      <xsl:when test="$mode = 'lexico3'">
        <xsl:value-of select="substring('                   ', 1, (2 * ($level -1)))"/>
        <xsl:text>&lt;head</xsl:text>
        <xsl:value-of select="$level - 1"/>
        <xsl:text>=</xsl:text>
        <xsl:value-of select="translate(normalize-space($text), '  ', '__')"/>
        <xsl:text>&gt;</xsl:text>
        <xsl:value-of select="$lf"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="substring('============', 1, $level)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="normalize-space($text)"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="substring('============', 1, $level)"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- chapter -->
    <!-- Redondant avec id ?
    <xsl:if test="$level=2">
      <xsl:text>
&lt;chapter=</xsl:text>
      <xsl:value-of select="translate(ancestor::tei:group[@xml:id]/@xml:id, 'morchesne_', '')" />
      <xsl:text>&gt;</xsl:text>
    </xsl:if>
    -->
  </xsl:template>

  
  <!-- Intertitre -->
  <xsl:template match="tei:label" mode="txt">
    <xsl:choose>
      <xsl:when test="parent::tei:quote and $mode = 'iramuteq'"/>
      <xsl:otherwise>
        <xsl:value-of select="$lf"/>
        <xsl:value-of select="$lf"/>
        <xsl:text>&lt; </xsl:text>
        <xsl:value-of select="normalize-space(.)"/>
        <xsl:text> &gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
 </xsl:template> 
  <xsl:template match="tei:dateline | tei:salute | tei:signed" mode="txt"/>

  <!-- Rétablissement de césure -->
  <xsl:template match="tei:caes" mode="txt">
    <xsl:choose>
      <xsl:when test="@whole">
        <xsl:value-of select="@whole"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Mot ajouté -->
  <xsl:template match="tei:supplied" mode="txt">
    <xsl:text>[</xsl:text>
    <xsl:apply-templates mode="txt"/>
    <xsl:text>]</xsl:text>
  </xsl:template>


  <!-- alternative critique -->
  <xsl:template match="tei:app" mode="txt">
    <xsl:apply-templates select="tei:lem" mode="txt"/>
  </xsl:template>
  <xsl:template match="tei:choice" mode="txt">
    <xsl:choose>
      <xsl:when test="tei:corr">
        <xsl:apply-templates select="tei:corr" mode="txt"/>
      </xsl:when>
      <xsl:when test="tei:expan">
        <xsl:apply-templates select="tei:expan" mode="txt"/>
      </xsl:when>
      <xsl:when test="tei:reg">
        <xsl:apply-templates select="tei:reg" mode="txt"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="*[1]" mode="txt"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Table -->
  <xsl:template match="tei:table" mode="txt">
    <xsl:value-of select="$lf"/>
    <xsl:apply-templates select="*" mode="txt"/>
    <xsl:value-of select="$lf"/>
  </xsl:template>

  <xsl:template match="tei:row" mode="txt">
    <xsl:apply-templates select="*" mode="txt"/>
    <xsl:value-of select="$lf"/>
  </xsl:template>

  <xsl:template match="tei:cell" mode="txt">
    <xsl:variable name="txt">
      <xsl:apply-templates mode="txt"/>
    </xsl:variable>
    <xsl:if test="preceding-sibling::tei:cell"> | </xsl:if>
    <xsl:value-of select="normalize-space($txt)"/>
  </xsl:template>
  
  <!-- one sentence by line in context  -->
  <xsl:template name="sent">
    <xsl:param name="txt" select="normalize-space(.)"/>
    <xsl:variable name="maj" select="translate($txt, 
      '?!.ABCDEFGHIJKLMNOPQRSTUVWXYZÀÇÉÈÊËÎÏÔÖŒÜÛ ', 
      '...@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ')"/>
    <xsl:choose>
      <xsl:when test="contains($maj, ' « @')">
        <xsl:variable name="pos" select="string-length(substring-before($maj, ' « @'))"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, 1, $pos)"/>
        </xsl:call-template>
        <xsl:value-of select="$lf"/>
        <xsl:text>    </xsl:text>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, $pos + 2)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($maj, '» @')">
        <xsl:variable name="pos" select="string-length(substring-before($maj, '» @'))"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, 1, $pos + 1)"/>
        </xsl:call-template>
        <xsl:value-of select="$lf"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, $pos + 3)"/>
        </xsl:call-template>
      </xsl:when>
      <!-- H. Spencer -->
      <xsl:when test="contains($maj, '@. @')">
        <xsl:variable name="pos" select="string-length(substring-before($maj, '@. @'))"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, 1, $pos+1)"/>
        </xsl:call-template>
        <xsl:text>. </xsl:text>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, $pos+4)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($maj, '. @')">
        <xsl:variable name="pos" select="string-length(substring-before($maj, '. @'))"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, 1, $pos+1)"/>
        </xsl:call-template>
        <xsl:value-of select="$lf"/>
        <xsl:call-template name="sent">
          <xsl:with-param name="txt" select="substring($txt, $pos + 3)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$txt"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <!-- For text, give back hand to normal processing, so that it could be overrides (= translate for some device) -->
  <xsl:template match="text()" mode="txt">
    <xsl:value-of select="translate(., concat($apos, '*­[]'), '’⁎')"/>
  </xsl:template>
</xsl:transform>
