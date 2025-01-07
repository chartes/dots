xquery version "3.1";

(:~  
: With this module, a DoTS user can add one or more collections to the 'resources register' of a db
: @author École nationale des chartes
: @since 2024-12-16
: @version  1.0
:)
module namespace add_collection = "backend/add_collections/project_add_collections"; 

import module namespace G = "globals";
import module namespace resources = "backend/resources_register_builder";
import module namespace functx = 'http://www.functx.com';

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


(:~  
: This updating function enables a DoTS user to add <collection/> nodes to the resources register of the db project.
: @param $dbName            db name
: @param $csvPath           absolute path to a CSV file
: @param $metadataMapping  absolute path to dots_metadataMapping.xml, if necessary.
: @return a sequence of <collection/> xml nodes
:)
declare updating function add_collection:addColl($dbName as xs:string, $csvPath as xs:string, $metadataMapping) {
  let $csv := if ($csvPath) then csv:doc($csvPath, map {
    "header": true(),
    "separator": $G:separator
  })
  let $metadata_map :=
    if ($metadataMapping)
    then 
      csv:doc($csvPath, map {
        "header": true(),
        "separator": $G:separator
      })
    else db:get($dbName, "/metadata/dots_metadata_mapping.xml")
  return
    if ($metadata_map)
    then
      for $record in $csv//*:record
      let $idCollName := normalize-space($metadata_map//*:mapping/node()[@scope="collection"][1]/@resourceId)
      let $idColl := normalize-space($record/node()[name() = $idCollName])
      let $parentIds := 
        if ($record/*:parentIds != "")
        then normalize-space($record/parentIds)
        else
          db:get($dbName, $G:resourcesRegister)//*:collection[not(@parentIds)]/@dtsResourceId
      return
        let $resources_register := db:get($dbName, $G:resourcesRegister)//member
        return
          insert node <collection dtsResourceId="{$idColl}" totalChildren="0" parentIds="{$parentIds}">{
            add_collection:getCollectionMetadata($dbName, $metadata_map, $record)
          }</collection> as last into $resources_register
    else update:output("You must provide a dots_metadataMapping.xml")
};

(:~ This function creates all the metadata to describe a collection
: @param $dbName        name of the db
: @param $metadata_map  dots_metadata_map file to use
: @param $record        csv metadata of a collection
: @return sequence of nodes with the metadata of a collection
: @see backend/resources_register_builder;resources:createContent
:)
declare function add_collection:getCollectionMetadata($dbName as xs:string, $metadata_map, $record as element(*:record)) {
  for $metadata in $metadata_map//mapping/node()[@scope = "collection"][@format="tsv"]
  return
    resources:createContent($metadata, $record)
};

declare function add_collection:totalChildren() {
  
};
