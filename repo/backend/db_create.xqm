xquery version "4.0";

(:~  
: This module provides a function to initialize a BaseX database for a DoTS project. It automates the loading of XML resources and associated metadata (e.g., mapping files and CSV/TSV tables), and configures the database with appropriate indexing and language settings.
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)
module namespace dots.create = "backend/db_create";

import module namespace functx = "http://www.functx.com";
import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

(:~  
: This function creates a database for a DoTS project, loading XML sources and metadata files.
: @param $dbName (xs:string) The name of the XML database to be created.
: @param $projectDirPath (xs:string) The path to the root directory of the DoTS project (containing /data/ and /metadata/).
: @return A new database with the given resources.
:)
declare updating function dots.create:db($dbName as xs:string, $projectDirPath as xs:string) {
  let $metadataPathFile := concat($projectDirPath, "/metadata/")
  let $mappingPathFile := if (file:exists($metadataPathFile)) then
    concat($metadataPathFile, file:list($metadataPathFile, true())[ends-with(., ".xml")])
  let $resourcesXML :=
    if (file:exists(concat($projectDirPath, "/data/")))
    then
      let $pathToData := concat($projectDirPath, "/data/")
      for $resource in file:list($pathToData, true())
      where contains($resource, ".xml")
      order by $resource
      return concat($pathToData, $resource)
    else ()
  let $csvData := 
    if (file:exists($metadataPathFile))
    then 
      for $document in file:list($metadataPathFile, true())
      where ends-with($document, ".csv") or ends-with($document, ".tsv")
      return csv:doc(
        concat($metadataPathFile, $document),
        map {
          "header": true(),
          "separator": if ($G:separator != "") then $G:separator else "	"
        }
      )
    else ()
  let $resources :=
    if ($mappingPathFile)
    then
      if ($csvData != "")
      then ($resourcesXML, $mappingPathFile, $csvData)
      else ($resourcesXML, $mappingPathFile)
    else $resourcesXML
  let $paths := (
    for $path in $resourcesXML return functx:substring-after-last($path, "/data/"),
    if ($mappingPathFile != "") then concat("/metadata/", file:name($mappingPathFile)) else (),
    if ($csvData != "") 
    then 
      for $document in file:list($metadataPathFile, true())
      where ends-with($document, ".csv") or ends-with($document, ".tsv")
      return concat("metadata/", functx:substring-after-last($document, "/metadata"))
    else ()
  )
  return db:create($dbName, $resources, $paths, map {
    "ftindex": true(),
    "updindex": true(),
    "tokenindex": true(),
    "stemming": true(),
    "language": if ($G:language) then $G:language else "fr"
  })
};
