xquery version "3.1";

(:~  
: This module allows adding a new document to an existing collection.
: @author École nationale des chartes - Philippe Pons
: @since 2025-01-10
: @version  1.0
:)

module namespace add_doc = "backend/update/add_document";

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace dots_error = "error/dots_error";
import module namespace resources = "backend/resources_register_builder";
import module namespace fragments = "backend/fragments_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ Update function to add a new document with a specific path
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @return add the document at the path $docPath to the db $dbName 
: @todo the script using this function MUST check if contains($docPath, "data/").
:)
declare %private updating function add_doc:addDocToDB($dbName as xs:string, $docPath) {
  let $path := substring-after($docPath, "data/")
  return
    db:put($dbName, $docPath, $path)
};

(:~ Update function to add a `<document/>` element to dots resources register (`dots/resources_register.xml`)
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @return a complete <document/> node
: @todo The script using this function MUST check, if a metadata TSV is called, whether information about the document is found in the TSV. If not, it should send a message specifying this.
:)
declare updating %private function add_doc:addDocToResourcesReg($dbName as xs:string, $docPath) {
  let $document := doc($docPath)/tei:TEI
  let $dtsResourceId := 
    if ($document/@xml:id)
    then $document/@xml:id
    else
      if (contains($docPath, "/"))
      then functx:substring-after-last($docPath, "/")
      else $docPath
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  let $parentIds := 
    if (contains($docPath, "/"))
    then
      let $path := functx:substring-before-last($docPath, "/")
      return
        let $collId := if (contains($path, "/")) then functx:substring-after-last($path, "/") else $path
        return
          try {
            dots_error:process(db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $collId])
          } catch add_doc:empty {
            'Error: ' || $err:description
          }
    else G:getTopCollectionId($dbName)
  return
    if ($document)
    then
      let $resources_register := db:get($dbName, $G:resourcesRegister)//dots:member
      return
        (
          insert node <document dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$parentIds}">{
          resources:getDocumentMetadata($dbName, $document, $dtsResourceId)
        }</document> as last into $resources_register,
        add_doc:updateMaxCiteDepthCollection($dbName, $parentIds),
        add_doc:addDocToSwitcherDots($dbName, $dtsResourceId)
        )
    else ()
};

(:~  Update function to add `<fragment/>` nodes to the fragments register (`dots/fragments_register`).
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @return sequence of <fragment/> nodes
:)
declare updating %private function add_doc:addFragInReg($dbName as xs:string, $docPath) {
  let $pathToDoc := functx:substring-after-last($docPath, "data/")
  let $document := db:get($dbName, $pathToDoc)/tei:TEI
  let $resourceId :=
    if ($document/@xml:id)
    then normalize-space($document/@xml:id)
    else functx:substring-after-last($pathToDoc, "/")
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  for $citeStructurePosition in $document//tei:refsDecl/tei:citeStructure
  return 
    let $fragments_register := db:get($dbName, $G:fragmentsRegister)//dots:member
    let $fragment := fragments:handleCiteStructure($dbName, $document, "", $citeStructurePosition, 1, $resourceId, "", "", $maxCiteDepth)
    return
      insert node $fragment as last into $fragments_register
};


(:~ Update function to increment the number of documents in a collection
: @param $dbName     db name
: @param $parentIds  identifier of the collection to update
: @return updating the value of the @totalChildren attribute in a <collection/> node.
:)
declare updating %private function add_doc:updateMaxCiteDepthCollection($dbName as xs:string, $parentIds as xs:string) {
  let $parent := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentIds]
  let $totalChildren := $parent/@totalChildren
  return
     if ($parentIds = "collection_error")
     then update:output("Collection does not exist !")
     else replace value of node $totalChildren with xs:integer($parent/@totalChildren) + 1
};

(:~ Updat function to add the documet to the switcher dots
: @param  $dbName         db name
: @param  $dtsResourceId  identifier of the document
: @return <document/> node
:)
declare updating %private function add_doc:addDocToSwitcherDots($dbName as xs:string, $dtsResourceId as xs:string) {
  let $switcher := db:get($G:dots, $G:dbSwitcher)//dots:member
  return
    insert node <document dtsResourceId="{$dtsResourceId}" dbName="{$dbName}"/> as last into $switcher
};
