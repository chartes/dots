xquery version "4.0";

(:~  
: This module allows updating the metadata file in a DoTS project.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-19
: @version  1.0
:)

module namespace update_metadata = "backend/update/update_metadata"; 

import module namespace G = "globals";

declare updating function update_metadata:deleteMetadata($dbName as xs:string) {
  let $metadataResources := db:list($dbName, $G:metadata)
  return
    for $resource in $metadataResources
    return
      db:delete($dbName, $resource)
};

declare updating function update_metadata:addNewMetadataDocument($dbName as xs:string, $metadataPath as xs:string, $d) {
  let $pathInMetadata := concat("metadata/", $d)
  return
    if (ends-with($d, ".tsv") or ends-with($d, ".csv")) 
    then 
      let $csv := csv:doc(
        concat("/", $metadataPath, "/", $d),
        map {
          "header": true(),
          "separator": if ($G:separator != "") then $G:separator else "	"
        }
      )
      return db:add($dbName, $csv, $pathInMetadata) 
    else db:add($dbName, concat($metadataPath, "/", $d), $pathInMetadata) 
};
  
  
  
  
  
  
  

