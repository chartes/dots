xquery version '4.0' ;

import module namespace G = "globals";
import module namespace resources = "backend/resources_register_builder";
import module namespace script = 'script';

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $resourceId external := ();
declare variable $parentId external := (); (: nécessaire ? Out of scope ? :)

if (db:exists($dbName))
then
  let $collection := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $resourceId]
  let $parent := if ($parentId) then $parentId else $collection/@parentIds
  let $csv := resources:getCSV-map($dbName, "collection")
  let $totalChildren := count(db:get($dbName, $G:resourcesRegister)//node()[@parentIds = $resourceId])
  return
    (
      replace node $collection with
        <collection xmlns="https://github.com/chartes/dots/" dtsResourceId="{$resourceId}" totalChildren="{$totalChildren}" parentIds="{$parent}">{
          resources:getCollectionMetadata($dbName, $resourceId, $csv)
        }</collection> 
    )
else script:error(concat("The database '", $dbName, "' doesn't exist."))