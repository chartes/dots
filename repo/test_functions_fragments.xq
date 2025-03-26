xquery version '4.0' ;

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace resources = "backend/resources_register_builder";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare variable $bdd := "cartulaires"; (: other possible values with your data : "encpos", "theater", "cid" :)

(:  
: The fragments registry built by the functions below optimizes DTS API responses, particularly for the Navigation endpoint. It provides a precomputed hierarchical structure of document fragments, enabling efficient exploration and retrieval of citable passages. For example, see: https://dev.chartes.psl.eu/dots/api/dts/navigation?resource=Maintenon&down=1
:)

(:~ 
: This function retrieves all TEI documents stored in the specified database and processes their citation structures (if available). It determines the maximum citation depth and calls local:handleCiteStructure recursively to generate a structured representation of the fragments.
: @param $bdd (xs:string): The name of the database to query.
: @return A sequence of <fragment> elements, each representing a citational unit extracted from the TEI documents
:)
declare function local:getFragments($bdd as xs:string) {
  for $resource in db:get($bdd)/tei:TEI
  where $resource//tei:citeStructure
  let $resourceId :=
    if ($resource/@xml:id)
    then normalize-space($resource/@xml:id)
    else functx:substring-after-last(db:path($resource), "/")
  let $maxCiteDepth := local:getMaxCiteDepth($resource//tei:refsDecl, 0)
  for $citeStructurePosition in $resource//tei:refsDecl/tei:citeStructure
  return local:handleCiteStructure($bdd, $resource, "", $citeStructurePosition, 1, $resourceId, "", "", $maxCiteDepth)
};

(:~ 
: This recursive function calculates the maximum depth of nested <tei:citeStructure> elements within a <tei:refsDecl>.
: @param $node (element()): The root <tei:refsDecl> element or a <tei:citeStructure> node.
: @param $n (xs:integer): The current depth level, initially set to 0.
: @return xs:integer: The maximum citation depth found in the document.
:)
declare function local:getMaxCiteDepth($node, $n as xs:integer) {
  let $levels :=
    for $level in $node
    return
      if ($node/tei:citeStructure)
      then
        local:getMaxCiteDepth($node/tei:citeStructure, $n + 1)
      else $n
  return
    max($levels)
};

(:~ 
: This function processes a given <tei:citeStructure> element, extracting fragment information and generating structured output. It evaluates XPath expressions dynamically and recursively processes nested structures.
: @param $bdd (xs:string): The database name.
: @param $resource (element()): The TEI document containing the citation structure.
: @param $parentNodeRef (xs:string or empty): The reference of the parent node.
: @param $citeStructure (element()): The <tei:citeStructure> element to process.
: @param $level (xs:integer): The current depth level in the citation hierarchy.
: @param $resourceId (xs:string): The identifier of the TEI resource.
: @param $parentRef (xs:string or empty): The reference to the parent node (if applicable).
: @param $parentNodeId (xs:string or empty): The node ID of the parent (if applicable).
: @param $maxCiteDepth (xs:integer): The maximum citation depth, as determined by local:getMaxCiteDepth
: @return a sequence of <fragment> elements, each representing a citation unit, with attributes for hierarchy and reference management.
:)
declare function local:handleCiteStructure($bdd as xs:string, $resource as element(), $parentNodeRef, $citeStructure as element(), $level as xs:integer, $resourceId, $parentRef, $parentNodeId, $maxCiteDepth) {
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
            if ($citeType) then attribute {"citeType"} {normalize-unicode($citeType)},
            if ($parentNodeId) then attribute {"parentNodeId"} {$parentNodeId},
            if ($parentNodeRef) then attribute {"parentNodeRef"} {$parentNodeRef},
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
                  element {$nameMetadata} {normalize-space($v)} else ()
          }</fragment>,
          if ($citeStructure/tei:citeStructure)
          then 
            for $cite in $citeStructure/tei:citeStructure
            return
              local:handleCiteStructure($bdd, $resource, $ref, $cite, $level + 1, $resourceId, $node-id, $node-id, $maxCiteDepth)
          else ()
        )
};

local:getFragments($bdd) => prof:track()





