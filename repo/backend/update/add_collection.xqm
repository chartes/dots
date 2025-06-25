xquery version "4.0";

module namespace add_coll = "backend/update/add_collection";

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace resources = "backend/resources_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";

declare updating function add_coll:handleAddition($dbName as xs:string, $resourceId as xs:string, $parentId as xs:string := "") {
  add_coll:addCollToResourcesReg($dbName, $resourceId, $parentId),
  add_coll:updateMaxCiteDepthCollection($dbName, $parentId),
  add_coll:addCollToSwitcherDots($dbName, $resourceId)
};

declare updating function add_coll:addCollToResourcesReg($dbName as xs:string, $resourceId as xs:string, $parentId as xs:string := "") {
  let $csv := resources:getCSV-map($dbName, $resourceId)
  let $parent := if ($parentId) then $parentId else utils_dots:getIdProject($dbName)
  let $resources_register := db:get($dbName, $G:resourcesRegister)//dots:member
  return
    insert node 
      <collection xmlns="https://github.com/chartes/dots/" dtsResourceId="{$resourceId}" totalChildren="0" parentIds="{$parent}">{
        resources:getCollectionMetadata($dbName, $resourceId, $csv)
      }</collection> as last into $resources_register
};

(:~ Update function to increment the number of documents in a collection
: @param $dbName     db name
: @param $parentIds  identifier of the collection to update
: @return updating the value of the @totalChildren attribute in a <collection/> node.
:)
declare updating %private function add_coll:updateMaxCiteDepthCollection($dbName as xs:string, $parentIds as xs:string) {
  let $idParentColl := if ($parentIds = "") then utils_dots:getIdProject($dbName) else $parentIds
  let $parent := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $idParentColl]
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