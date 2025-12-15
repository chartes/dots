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
import module namespace dots.update = "backend/TEI_add_id";
import module namespace script = "script";
import module namespace utils_dots = "utils_dots"; 
import module namespace store_clear = "backend/update/store_clear";
import module namespace update_metadata = "backend/update/update_metadata";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ Update function to handle the addition of a new document and its fragments to the database and registers.
: @param $dbName   db name
: @param $docPath  absolute path to the document to add
: @return updates the database and registers with the new document and its fragments
:)
declare updating function add_doc:handleAddition($dbName as xs:string, $docPath as xs:string, $parentId as xs:string, $projectDirPath := "") {
  if ($projectDirPath)
      then
        (
          update_metadata:deleteMetadata($dbName),
          update_metadata:addNewMetadataDocument($dbName, concat($projectDirPath, "/metadata"))
        ),
  let $resourceId := utils_dots:findDocId($docPath)
  let $docInRegister := utils_dots:getDocInRegister($dbName, $resourceId) 
  return
    if ($docInRegister)
    then script:error(dots_error:documentExists())
    else
      let $csv := resources:getCSV-map($dbName, "document")
      return
      (
        add_doc:addDocToDB($dbName, $docPath, $parentId),
        add_doc:addDocToResourcesReg($dbName, $docPath, $csv, $parentId),
        store_clear:clear($dbName, $dbName),
        if ($parentId) 
        then store_clear:clear($dbName, $parentId)
  )
};

(:~~~~~~~~~~~~~~~
Update database
~~~~~~~~~~~~~~~~~:)

(:~ Update function to add a new document with a specific path
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @param $parentId identifier of the parent collection. By default, the project identifier.
: @return add the document at the path $docPath to the db $dbName 
:)
declare %private updating function add_doc:addDocToDB($dbName as xs:string, $docPath as xs:string, $path as xs:string) {
  let $docName := functx:substring-after-last($docPath, "/")
  return
    db:put($dbName, $docPath, concat($path, "/", $docName))
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~
Update resources_register.xml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ Update function to add a `<document/>` element to dots resources register (`dots/resources_register.xml`)
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @param $csv map of the csv metadata
: @return a complete <document/> node
:)
declare updating %private function add_doc:addDocToResourcesReg($dbName as xs:string, $docPath as xs:string, $csv, $parentId as xs:string := "") {
  let $document := doc($docPath)/tei:TEI
  let $projectName := G:getTopCollectionId($dbName)
  let $dtsResourceId := 
    if ($document/@xml:id)
    then $document/@xml:id
    else
      if (contains($docPath, "/"))
      then functx:substring-after-last($docPath, "/")
      else $docPath
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  let $parentIds := 
    if ($parentId)
    then $parentId
    else $projectName
  return
    let $resources_register := db:get($dbName, $G:resourcesRegister)//dots:member
    return
      (
        insert node <document xmlns="https://github.com/chartes/dots/" dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$parentIds}">{
        resources:getDocumentMetadata($dbName, $document, $dtsResourceId, $csv),
        resources:getDotsProjectName($projectName)
  }</document> as last into $resources_register,
        add_doc:updateTotalChildrenCollection($dbName, $parentIds),
        add_doc:addDocToSwitcherDots($dbName, $dtsResourceId)
      )
};

(:~ Update function to increment the number of documents in the parent collection
: @param $dbName     db name
: @param $parentIds  identifier of the collection to update
: @return updating the value of the @totalChildren attribute in a <collection/> node.
:)
declare updating %private function add_doc:updateTotalChildrenCollection($dbName as xs:string, $parentIds as xs:string) {
  let $parent := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentIds]
  let $totalChildren := $parent/@totalChildren
  return
     if ($parent != "")
     then replace value of node $totalChildren with xs:integer($parent/@totalChildren) + 1
     else 
       update:output("La collection parente n'existe pas.")
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~
Update fragments_register.xml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ Update function to handle the addition of fragments from a new document to the fragments register.
: @param $dbName   db name
: @param $docPath  absolute path to the document containing the fragments to add
: @return updates the fragments register with the new fragments
:)
declare updating function add_doc:handleFragmentsAddition($dbName as xs:string, $docPath) {
  let $csv-frag := resources:getCSV-map($dbName, "fragment")
  return
    add_doc:addFragInReg($dbName, $docPath, $csv-frag)
};

(:~  Update function to add `<fragment/>` nodes to the fragments register (`dots/fragments_register`).
: @param $dbName  db name
: @param $docPath absolute path to the document to add
: @return sequence of <fragment/> nodes
:)
declare updating %private function add_doc:addFragInReg($dbName as xs:string, $docPath, $csv) { 
  let $resourceId :=
    if (doc($docPath)/*:TEI/@xml:id)
    then normalize-space(doc($docPath)/*:TEI/@xml:id)
    else functx:substring-after-last($docPath, "/")
  let $document := utils_dots:getDocument($dbName, $resourceId)
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  for $citeStructurePosition in $document//tei:refsDecl/tei:citeStructure
  return 
    let $fragments_register := db:get($dbName, $G:fragmentsRegister)//dots:member
    let $fragment := fragments:handleCiteStructure($dbName, $document, "", $citeStructurePosition, 1, $resourceId, "", "", $maxCiteDepth, $csv)
    let $oldFragments := $fragments_register/dots:fragment[@resourceId = $resourceId]
    return
      if ($oldFragments)
      then
        (
          delete nodes $oldFragments,
          insert node $fragment as last into $fragments_register
        )
      else insert node $fragment as last into $fragments_register
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~
Update switcher DoTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

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










