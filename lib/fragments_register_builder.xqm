xquery version "3.1";

(:~  
: Ce module permet de lister tous les fragments disponibles dans les documents
: @author École nationale des chartes - Philippe Pons
: @since 2023-07-26
: @version  1.0
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib";

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
declare updating function dots.lib:createFragmentsRegister($bdd) {
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
        dots.lib:getMetadata(),
        <member>{$fragments}</member>
      }</fragmentsRegister>
    return
      if ($fragments)
      then
        db:add($bdd, $content, $G:fragmentsRegister)
      else ()
};

declare function dots.lib:getFragments($bdd as xs:string) {
  for $resource in db:get($bdd)/tei:TEI
  where $resource//tei:citeStructure
  let $resourceId :=
    if ($resource/@xml:id)
    then normalize-space($resource/@xml:id)
    else functx:substring-after-last(db:path($resource), "/")
  let $maxCiteDepth := dots.lib:getMaxCiteDepth($resource//tei:refsDecl, 0)
  return
    for $citeStructurePosition in $resource//tei:refsDecl/tei:citeStructure
    return
      dots.lib:handleCiteStructure($bdd, $resource, $citeStructurePosition, 1, $resourceId, "", "", $maxCiteDepth)
};

declare function dots.lib:handleCiteStructure($bdd as xs:string, $resource as element(), $citeStructure as element(), $level as xs:integer, $resourceId, $parentRef, $parentNodeId, $maxCiteDepth) {
  let $xpath := normalize-space($citeStructure/@match)
  let $query := concat('
    declare default element namespace "http://www.tei-c.org/ns/1.0";',
    $xpath)
  let $use := normalize-space($citeStructure/@use)
  let $citeType := normalize-unicode($citeStructure/@unit)
  return
    if ($xpath)
    then
      for $fragment at $pos in xquery:eval($query, map {"": if ($parentNodeId) then $resource//db:get-id($bdd, $parentNodeId) else $resource})
      let $n :=
        if ($parentRef)
        then concat($parentRef, ".", $pos)
        else $pos
      let $node-id := db:node-id($fragment)
      let $ref :=
        if ($use = "@xml:id")
        then 
          if ($fragment/@xml:id)
          then normalize-space($fragment/@xml:id)
          else $n
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
              let $xpathCiteData := $citeData/@use
              let $query := concat('
                declare default element namespace "http://www.tei-c.org/ns/1.0";',
                $xpathCiteData)
              let $valueQuery := xquery:eval($query, map {"": $fragment})
              return
                for $v in $valueQuery
                return
                  element {$nameMetadata} {normalize-space($v)} else (),
            if ($fragment/@xml:id)
            then
              dots.lib:getFragmentMetadata($bdd, xs:string($ref))
            else ()
          }</fragment>,
          if ($citeStructure/tei:citeStructure)
          then 
            for $cite in $citeStructure/tei:citeStructure
            return
              dots.lib:handleCiteStructure($bdd, $resource, $cite, $level + 1, $resourceId, $n, $node-id, $maxCiteDepth)
          else ()
        )
};

declare function dots.lib:getFragmentMetadata($bdd as xs:string, $ref as xs:string) {
  let $metadataMap :=  db:get($bdd, $G:metadata)//metadataMap
  return
    let $metadatas := 
    for $metadata in $metadataMap//mapping/node()[@scope = "fragment"]
    let $getResourceId := $metadata/@resourceId
    let $source := functx:substring-after-last($metadata/@source, "/")
    let $csv := 
      for $csvs in db:get($bdd)//*:csv
      let $paths := db:path($csvs)
      where contains($paths, $source)
      return
        $csvs[1]
    let $findIdInCSV := normalize-space($metadata/@resourceId)
    let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $ref]]       
    return
      if ($metadata/@resourceId = "all")
      then 
        let $key := $metadata/name()
        return
          element {$key} { concat($metadata/@prefix, $metadata, $metadata/@suffix) }
      else
        if ($record and $metadata) 
        then dots.lib:createContent($metadata, $record)
        else ()
  return
    $metadatas
};

declare function dots.lib:getMaxCiteDepth($node, $n as xs:integer) {
  let $levels :=
    for $level in $node
    return
      if ($node/tei:citeStructure)
      then
        dots.lib:getMaxCiteDepth($node/tei:citeStructure, $n + 1)
      else $n
  return
    max($levels)
};




