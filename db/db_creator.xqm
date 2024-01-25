xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de créer sa base de données BaseX
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)

module namespace dbc = "https://github.com/chartes/dots/db/dbc";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace functx = "http://www.functx.com";
import module namespace var = "https://github.com/chartes/dots/variables" at "../project_variables.xqm";

declare updating function dbc:dbCreate($dbName as xs:string, $pathPaquet as xs:string) {
  let $metadataPathFile := concat($pathPaquet, "/metadata/")
  let $mappingPathFile := if (file:exists($metadataPathFile)) then concat($metadataPathFile, file:list($metadataPathFile, true())[ends-with(., ".xml")])
  let $resourcesXML :=
    if (file:exists(concat($pathPaquet, "/data")))
    then
      let $pathToData := concat($pathPaquet, "/data/")
      for $resource in file:list($pathToData, true())
      where contains($resource, ".xml")
      order by $resource
      return
        concat($pathToData, $resource)
  let $csvData := 
      if (file:exists($metadataPathFile))
      then 
        for $document in file:list($metadataPathFile, true())
        where ends-with($document, ".csv") or ends-with($document, ".tsv")
        return
          csv:doc(concat($metadataPathFile, $document), map{
          "header": true(),
          "separator": if ($var:separator != "") then $var:separator else "	"}
            )
      else ()
  let $resources :=
    if ($mappingPathFile)
    then
      if ($csvData != "")
      then ($resourcesXML, $mappingPathFile, $csvData)
      else ($resourcesXML, $mappingPathFile)
    else $resourcesXML
  let $paths :=
    (
      for $path in $resourcesXML return substring-after($path, "/data/"),
      if ($mappingPathFile != "") then concat("/metadata/", file:name($mappingPathFile)) else (),
      if ($csvData != "") 
      then 
        for $document in file:list($metadataPathFile, true())
        where ends-with($document, ".csv") or ends-with($document, ".tsv")
        return 
          concat("metadata/", functx:substring-after-last($document, "/metadata"))
      else ()
    )
  return
    db:create($dbName, $resources, $paths, map {
      "ftindex": true(),
      "updindex": true(),
      "stemming": true(),
      "language": if ($var:language) then $var:language else "fr"
    })
};
