xquery version "3.1";

(:~  
: Ce module permet de lister tous les fragments disponibles dans les documents
: @author École nationale des chartes - Philippe Pons
: @since 2023-07-26
: @version  1.0
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib/fragments";

import module namespace dots.resources = "https://github.com/chartes/dots/lib" at "resources_register_builder.xqm";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

import module namespace functx = 'http://www.functx.com';

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ 
: Cette fonction permet de construire ou mettre à jour documentRegister.xml qui liste les fragments disponibles dans les documents
: @return document XML à ajouter à la db $bdd
: @param $bdd chaîne de caractères qui correspond au nom de la base de données
:)
declare updating function dots.lib:createDocumentRegister($bdd) {
  if (db:exists($bdd, $G:fragmentsRegister))
  then 
    let $register := db:get($bdd, $G:fragmentsRegister)
    let $lastUpdate := $register//dct:modified
    let $members := $register//member
    return
      (
        replace value of node $lastUpdate with current-dateTime(),
        replace node $members with <member>{dots.lib:getFragments($bdd)}</member>
      )
  else
    let $fragments := dots.lib:getFragments($bdd)
    let $content := 
      <fragmentsRegister>{
        dots.resources:getMetadata(),
        <member>{$fragments}</member>
      }</fragmentsRegister>
    return
      if ($fragments)
      then
        db:add($bdd, $content, $G:fragmentsRegister)
      else ()
};

(:~ 
: @todo intégrer une fonction (récursive) pour le traitement de citeStructure
:)
declare function dots.lib:getFragments($bdd as xs:string) {
  for $resource in db:get($bdd)/tei:TEI
  where $resource//tei:citeStructure
  let $resourceId :=
    if ($resource/@xml:id)
    then normalize-space($resource/@xml:id)
    else functx:substring-after-last(db:path($resource), "/")
  let $maxCiteDepth := count($resource//tei:refsDecl//tei:citeStructure)
  return
    for $citeStructurePosition at $pos in $resource//tei:refsDecl/tei:citeStructure
    return
      dots.lib:handleCiteStructure($bdd, $resource, 1, $resourceId, "", "", $maxCiteDepth, $pos)
};

declare function dots.lib:handleCiteStructure($bdd as xs:string, $resource as element(), $level as xs:integer, $resourceId, $parentRef, $parentNodeId, $maxCiteDepth as xs:integer, $position as xs:integer) {
  let $citeStructure :=
    if ($position = 0)
    then for $c in $resource//tei:refsDecl/descendant::tei:citeStructure[$level] return $c
    else $resource//tei:refsDecl/tei:citeStructure[$position]
  let $xpath := normalize-space($citeStructure/@match)
  let $query := concat('
    declare default element namespace "http://www.tei-c.org/ns/1.0";',
    $xpath)
  let $use := normalize-space($citeStructure/@use)
  let $citeType := normalize-unicode($citeStructure/@unit)
  return
    if ($xpath) then
    for $fragment at $pos in xquery:eval($query, map {"": if ($parentNodeId) then $resource//db:get-id($bdd, $parentNodeId) else $resource})
    let $n :=
      if ($parentRef)
      then concat($parentRef, ".", $pos)
      else $pos
    let $node-id := db:node-id($fragment)
    let $ref :=
      if ($use != "position()")
      then normalize-space($fragment/@*[name() = substring-after($use, "@")])
      else $n
    return
      (
        <fragment n="{$n}" node-id="{$node-id}" ref="{$ref}" level="{$level}" maxCiteDepth="{$maxCiteDepth}" resourceId="{$resourceId}">{
          if ($citeType) then attribute {"citeType"} {normalize-unicode($citeType)} else (),
          if ($parentNodeId) then attribute {"parentNodeId"} {$parentNodeId} else (),
          if ($citeStructure/tei:citeData)
          then
            for $citeData in $citeStructure/tei:citeData
            let $nameMetadata := normalize-space($citeData/@property)
            let $xpath := $citeData/@use
            let $query := concat('
              declare default element namespace "http://www.tei-c.org/ns/1.0";',
              $xpath)
            let $valueQuery := xquery:eval($query, map {"": $fragment})
            return
              if ($valueQuery) then element {$nameMetadata} {normalize-space($valueQuery[1])} else ()
          else ()
        }</fragment>,
        if ($citeStructure/tei:citeStructure)
        then 
          dots.lib:handleCiteStructure($bdd, $resource, $level + 1, $resourceId, $n, $node-id, $maxCiteDepth, 0)
        else ()
      )
};






