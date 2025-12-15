xquery version "4.0";

module namespace add_coll = "backend/update/add_collection";

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace resources = "backend/resources_register_builder";
import module namespace update_metadata = "backend/update/update_metadata"; 

declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare namespace dots = "https://github.com/chartes/dots/";

(:~ Main function to handle the addition of a collection to the database.
: It updates the resources register, the MaxCiteDepth of the parent collection, and the switcher dots.
: @param $dbName      Name of the database
: @param $resourceId  Identifier of the collection to add
: @param $parentId    Identifier of the parent collection (optional)
:)
declare updating function add_coll:handleAddition(
  $dbName          as xs:string, 
  $resourceId      as xs:string, 
  $parentId        as xs:string := "", 
  $projectDirPath  as xs:string := "") {
  let $parent := if ($parentId) then $parentId else utils_dots:getIdProject($dbName)
  return
    (
      if ($projectDirPath)
      then
        (
          update_metadata:deleteMetadata($dbName),
          update_metadata:addNewMetadataDocument($dbName, concat($projectDirPath, "/metadata"))
        ),
      add_coll:addCollToResourcesReg($dbName, $resourceId, $parent),
      add_coll:updateMaxCiteDepthCollection($dbName, $parent),
      add_coll:addCollToSwitcherDots($dbName, $resourceId)
    )
};

(:~ Function to add a collection to the resources register.
: It inserts a new <collection/> node with metadata and updates the parent relationship.
: @param $dbName      Name of the database
: @param $resourceId  Identifier of the collection to add
: @param $parentId    Identifier of the parent collection (optional)
: @return Inserts a new <collection/> node into the resources register.
:)
declare updating function add_coll:addCollToResourcesReg($dbName as xs:string, $resourceId as xs:string, $parentId as xs:string) {
  let $csv := resources:getCSV-map($dbName, "collection")
  let $resources_register := db:get($dbName, $G:resourcesRegister)//dots:member
  let $metadata := resources:getCollectionMetadata($dbName, $resourceId, $csv)
  return
    insert node 
      <collection xmlns="https://github.com/chartes/dots/" dtsResourceId="{$resourceId}" totalChildren="0" parentIds="{$parentId}">{
        if ($metadata/descendant-or-self::*:title)
        then
          $metadata
        else
          (
            <dc:title>{$resourceId}</dc:title>,
            $metadata
          )
      }</collection> as last into $resources_register
};

(:~ Update function to increment the number of documents in a collection
: @param $dbName     db name
: @param $parentIds  identifier of the collection to update
: @return updating the value of the @totalChildren attribute in a <collection/> node.
:)
declare updating %private function add_coll:updateMaxCiteDepthCollection($dbName as xs:string, $parentId as xs:string) {
  let $parent := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentId]
  let $totalChildren := $parent/@totalChildren
  return
     if ($parent != "")
     then replace value of node $totalChildren with xs:integer($parent/@totalChildren) + 1
     else 
       update:output("La collection parente n'existe pas.")
};

(:~ Update function to add the collection to the switcher dots
: @param  $dbName         db name
: @param  $dtsResourceId  identifier of the collection
: @return <document/> node
:)
declare updating function add_coll:addCollToSwitcherDots($dbName as xs:string, $dtsResourceId as xs:string) {
  let $switcher := db:get($G:dots, $G:dbSwitcher)//dots:member
  return
    insert node <collection dtsResourceId="{$dtsResourceId}" dbName="{$dbName}"/> as last into $switcher
};