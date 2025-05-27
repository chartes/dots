xquery version "4.0";

module namespace add_coll = "backend/update/add_collection";

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace resources = "backend/resources_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";

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