xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de créer sa base de données BaseX
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare updating function dots.lib:dbCreate($dbName as xs:string, $projectDirPath as xs:string) {
  let $metadataPathFile := concat($projectDirPath, "/metadata/")
  let $mappingPathFile := if (file:exists($metadataPathFile)) then concat($metadataPathFile, file:list($metadataPathFile, true())[ends-with(., ".xml")])
  let $resourcesXML :=
    if (file:exists(concat($projectDirPath, "/data/")))
    then
      let $pathToData := concat($projectDirPath, "/data/")
      for $resource in file:list($pathToData, true())
      where contains($resource, ".xml")
      order by $resource
      return
        concat($pathToData, $resource)
    else()
  let $csvData := 
      if (file:exists($metadataPathFile))
      then 
        for $document in file:list($metadataPathFile, true())
        where ends-with($document, ".csv") or ends-with($document, ".tsv")
        return
          csv:doc(concat($metadataPathFile, $document), map{
          "header": true(),
          "separator": if ($G:separator != "") then $G:separator else "	"}
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
      for $path in $resourcesXML return functx:substring-after-last($path, "/data/"),
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
      "language": if ($G:language) then $G:language else "fr"
    })
};
