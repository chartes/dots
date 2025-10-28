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

declare updating function update_metadata:addNewMetadataDocument(
  $dbName as xs:string,
  $metadataPath as xs:string
) {
  let $metadata := concat($metadataPath, '/dots_metadata_mapping.xml')
  return (
    if (not(file:exists($metadata))) then
      error((), $metadata || ' is missing') else

    for $file in file:list($metadataPath)
    let $pathInMetadata := concat("metadata/", $file)
    let $suffix := lower-case(replace($file, '^.*\.', ''))
    let $input := if ($suffix = ('tsv', 'csv')) then (
      csv:doc(
        concat("/", $metadataPath, "/", $file),
        map {
          "header": true(),
          "separator": if ($G:separator != "") then $G:separator else "	"
        }
      )
    ) else if ($suffix = ('xml')) then (
      fetch:doc(concat($metadataPath, "/", $file))
    ) else (
      error((), 'Unknown file type: ' || $suffix)
    )
    return db:add($dbName, $input, $pathInMetadata)
  )
};
