xquery version "3.1";

(:~  
: Ce module permet de lister tous les fragments disponibles dans les documents
: @author École nationale des chartes - Philippe Pons
: @since 2023-07-26
: @version  1.0
:)
module namespace fragments = "backend/fragments_register_builder";

import module namespace functx = 'http://www.functx.com';
import module namespace resources = "backend/resources_register_builder";
import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ 
: The fragments registry built by the functions below optimizes DTS API responses, particularly for the Navigation endpoint. It provides a precomputed hierarchical structure of document fragments, enabling efficient exploration and retrieval of citable passages.
:)

(:~ 
: This function generates and stores a fragment registry for the specified database. It collects fragment information from fragments:getFragments and combines it with metadata before saving it as a new document in the database.
: @param $bdd (xs:string) The name of the database to query.
: @return A new document named fragments_register.xml is added to the database
:)
declare updating function fragments:createFragmentsRegister($dbName as xs:string) {
  let $csv := resources:getCSV-map($dbName, "fragment")
  let $fragments := fragments:getFragments($dbName, $csv)
  where $fragments
  return
    let $content := 
      <fragmentsRegister>{
        resources:getMetadata(),
        <member>{$fragments}</member>
      }</fragmentsRegister>
    return db:add($dbName, $content, $G:fragmentsRegister)
};

(:~ 
: This function retrieves all TEI documents stored in the specified database and processes their citation structures (if available). It determines the maximum citation depth and calls local:handleCiteStructure recursively to generate a structured representation of the fragments.
: @param $bdd (xs:string) The name of the database to query.
: @return A sequence of <fragment> elements, each representing a citational unit extracted from the TEI documents
:)
declare %private function fragments:getFragments($bdd as xs:string, $csv) {
  for $resource in db:get($bdd)/tei:TEI
  where $resource//tei:citeStructure
  let $resourceId :=
    if ($resource/@xml:id)
    then normalize-space($resource/@xml:id)
    else functx:substring-after-last(db:path($resource), "/")
  let $maxCiteDepth := fragments:getMaxCiteDepth($resource//tei:refsDecl, 0)
  for $citeStructurePosition in $resource//tei:refsDecl/tei:citeStructure
  return fragments:handleCiteStructure($bdd, $resource, "", $citeStructurePosition, 1, $resourceId, "", "", $maxCiteDepth, $csv)
};

(:~ 
: This function processes a given <tei:citeStructure> element, extracting fragment information and generating structured output. It evaluates XPath expressions dynamically and recursively processes nested structures.
: @param $bdd (xs:string) The database name.
: @param $resource (element()) The TEI document containing the citation structure.
: @param $parentNodeRef (xs:string or empty) The reference of the parent node.
: @param $citeStructure (element()) The <tei:citeStructure> element to process.
: @param $level (xs:integer) The current depth level in the citation hierarchy.
: @param $resourceId (xs:string) The identifier of the TEI resource.
: @param $parentRef (xs:string or empty) The reference to the parent node (if applicable).
: @param $parentNodeId (xs:string or empty) The node ID of the parent (if applicable).
: @param $maxCiteDepth (xs:integer) The maximum citation depth, as determined by local:getMaxCiteDepth
: @return a sequence of <fragment> elements, each representing a citation unit, with attributes for hierarchy and reference management.
:)
declare function fragments:handleCiteStructure($bdd as xs:string, $resource as element(), $parentNodeRef, $citeStructure as element(), $level as xs:integer, $resourceId, $parentRef, $parentNodeId, $maxCiteDepth, $csv) {
  let $xpath := normalize-space($citeStructure/@match)
  let $query := concat('
    declare default element namespace "http://www.tei-c.org/ns/1.0";',
    $xpath)
  let $use := normalize-space($citeStructure/@use)
  let $citeType := normalize-unicode($citeStructure/@unit)
  return
    if ($xpath)
    then
      for $fragment in xquery:eval($query, map {"": if ($parentNodeId) then db:get-id($bdd, $parentNodeId) else $resource})
      let $node-id := db:node-id($fragment)
      let $ref :=
        if ($use = "@xml:id")
        then 
          if ($fragment/@xml:id)
          then normalize-space($fragment/@xml:id)
          else concat("r", $node-id)
        else concat("r", $node-id)
      return
        (
          <fragment node-id="{$node-id}" ref="{$ref}" level="{$level}" maxCiteDepth="{$maxCiteDepth}" resourceId="{$resourceId}">{
            if ($citeType) then attribute {"citeType"} {normalize-unicode($citeType)} else (),
            if ($parentNodeId) then attribute {"parentNodeId"} {$parentNodeId} else (),
            if ($parentNodeRef) then attribute {"parentNodeRef"} {$parentNodeRef} else (),
            if ($citeStructure/tei:citeData)
            then
              for $citeData in $citeStructure/tei:citeData
              let $nameMetadata := normalize-space($citeData/@property)
              let $xpathCiteData := $citeData/@use
              let $query := concat('
                declare default element namespace "http://www.tei-c.org/ns/1.0"; declare namespace functx = "http://www.functx.com";',
                $xpathCiteData)
              let $valueQuery := xquery:eval($query, map {"": $fragment})
              return
                for $v in $valueQuery
                return
                  element {$nameMetadata} {normalize-space($v)} else (),
            fragments:getFragmentMetadata($bdd, xs:string($ref), $csv)
          }</fragment>,
          if ($citeStructure/tei:citeStructure)
          then 
            for $cite in $citeStructure/tei:citeStructure
            return
              fragments:handleCiteStructure($bdd, $resource, $ref, $cite, $level + 1, $resourceId, $node-id, $node-id, $maxCiteDepth, $csv)
          else ()
        )
};

(:~  
: This function retrieves metadata associated with a specific fragment in a given database. It looks up metadata mappings, cross-references CSV-based data, and constructs relevant metadata elements.
: @param $bdd (xs:string) The name of the database where the fragment is stored.
: @param $ref (xs:string) The reference identifier of the fragment whose metadata needs to be retrieved.
: @return A sequence of metadata elements specific to the requested fragment
:)
declare %private function fragments:getFragmentMetadata($dbName as xs:string, $ref as xs:string, $csv-map) {
  (: let $metadataMap :=  db:get($bdd, $G:metadata)//metadataMap
  return
    let $metadatas := 
      let $csv-map := resources:getCSV-map($bdd, "fragment")
      for $metadata in $metadataMap//mapping/node()[@scope = "fragment"]
      let $source := functx:substring-after-last($metadata/@source, "/")
      let $csv := $csv-map($source)
      let $findIdInCSV := normalize-space($metadata/@resourceId)
      let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $ref]]       
      return
        if ($metadata/@resourceId = "all")
        then 
          let $key := $metadata/name()
          return
            element {$key} { 
            if ($metadata/@key) then attribute {"key"} {$metadata/@key},
            concat($metadata/@prefix, $metadata, $metadata/@suffix) 
            }
        else
          if ($record and $metadata) 
          then resources:createContent($metadata, $record)
          else ()
  return
    $metadatas :)
    
let $metadataMap :=  db:get($dbName, $G:metadata)//metadataMap/mapping
return
  if ($metadataMap)
  then
    for $metadata in $metadataMap/node()[@scope = "fragment"]
    return
      if ($metadata/@resourceId = "all")
      then 
        let $key := $metadata/name()
        return element {$key} { 
          if ($metadata/@key) then attribute {"key"} {$metadata/@key},
          concat($metadata/@prefix, $metadata, $metadata/@suffix) 
        }
      else 
        let $source := functx:substring-after-last($metadata/@source, '/')
        let $csv-source := $csv-map($source)
        for $record in $csv-source($ref)
        return
          resources:createContent($metadata, $record)
};

(:~ 
: This recursive function calculates the maximum depth of nested <tei:citeStructure> elements within a <tei:refsDecl>.
: @param $node (element()) The root <tei:refsDecl> element or a <tei:citeStructure> node.
: @param $n (xs:integer) The current depth level, initially set to 0.
: @return xs:integer: The maximum citation depth found in the document.
:)
declare function fragments:getMaxCiteDepth($node, $n as xs:integer) {
  let $levels :=
    for $level in $node
    return
      if ($node/tei:citeStructure)
      then
        fragments:getMaxCiteDepth($node/tei:citeStructure, $n + 1)
      else $n
  return
    max($levels)
};
