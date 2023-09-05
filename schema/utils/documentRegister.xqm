xquery version "3.1";

(:~  
: Ce module permet de lister tous les fragments disponibles dans les documents
: @author École nationale des chartes - Philippe Pons
: @since 2023-07-26
: @version  1.0
: @todo ajouter ici les documents eux-mêmes. (À confirmer) => non, je ne suis pas sûr
:)

module namespace docR = "https://github.com/chartes/dots/schema/utils/docR";

import module namespace G = "https://github.com/chartes/dots/globals" at "../../globals.xqm";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ 
: Cette fonction permet de construire ou mettre à jour documentRegister.xml qui liste les fragments disponibles dans les documents
: @return document XML à ajouter à la db $bdd
: @param $bdd chaîne de caractères qui correspond au nom de la base de données
:)
declare updating function docR:createDocumentRegister($bdd) {
  if (db:exists($bdd, $G:register))
  then 
    let $register := db:get($bdd, $G:register)
    let $lastUpdate := $register//dots:lastUpdate
    let $members := $register//dots:members
    return
      (
        replace value of node $lastUpdate with current-dateTime(),
        replace node $members with <dots:members>{docR:getFragments($bdd)}</dots:members>
      )
  else
    let $content := 
      <dots:documents xmlns:dots="https://github.com/chartes/dots/">{
        docR:getMetadata(),
        <dots:documentsContent>
          <dots:members>{
            docR:getFragments($bdd)
          }</dots:members>
        </dots:documentsContent>
      }</dots:documents>
    return
      db:add($bdd, $content, $G:register)
};

(:~ 
: Cette fonction se contente de construire l'en-tête <dots:configMetadata/> de documentRegister.xml
:)
declare function docR:getMetadata() {
  <dots:documentsMetadata>
    <dots:gitVersion/><!-- version git du fichier -->
    <dots:creationDate>{current-dateTime()}</dots:creationDate><!-- date de création du document -->
    <dots:lastUpdate>{current-dateTime()}</dots:lastUpdate><!-- date de la dernière mise à jour -->
    <dots:publisher>École nationale des chartes</dots:publisher>
    <dots:description>{string("Registre des documents disponibles et leurs fragments pour l'API DTS")}</dots:description>
    <dots:licence>https://opensource.org/license/mit/</dots:licence>
  </dots:documentsMetadata>
};

(:~ 
: @todo intégrer l'usage, en plus de cRefPattern, de citeStructure
:)
declare function docR:getFragments($bdd as xs:string) {
  for $resource in db:get($bdd)/tei:TEI
  let $path := db:path($resource)
  let $idResource := normalize-space($resource/@xml:id)
  let $cRefPattern := $resource//tei:encodingDesc/tei:refsDecl[@n = "DTS"]/tei:cRefPattern
  let $level := substring-after($cRefPattern/@n, "level")
  let $xpath := normalize-space($cRefPattern/@replacementPattern)
  let $maxCiteDepth := count($resource//tei:encodingDesc/tei:refsDecl[@n = "DTS"]/tei:cRefPattern)
  order by $idResource
  return
    for $fragments at $pos in xquery:eval(replace($xpath, "/[a-zA-Z]+:", "/*:"), map {"": db:get($bdd, $path)})
    let $id := $fragments/@xml:id
    let $node-id := db:node-id($fragments)
    let $title := normalize-space($fragments/tei:head)
    let $date := normalize-space($fragments/tei:head//tei:date/@when)
    order by $pos
    return 
      <dots:member level="{$level}" maxCiteDepth="{$maxCiteDepth}" ref="{$pos}" target="#{$idResource}">{
        if ($id) then attribute {"xml:id"} {$id} else attribute {"node-id"} {$node-id},
        if ($title) then <dc:title>{$title}</dc:title> else (),
        if ($date) then <dc:date>{$date}</dc:date> else ()
      }</dots:member> 
};

