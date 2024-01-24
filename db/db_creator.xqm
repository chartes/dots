xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de créer sa base de données BaseX
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)

module namespace dbc = "https://github.com/chartes/dots/db/dbc";

import module namespace functx = "http://www.functx.com";
import module namespace var = "https://github.com/chartes/dots/variables" at "../project_variables.xqm";


declare updating function dbc:dbCreate($dbName as xs:string) {
  let $resourcesXML :=
    for $resource in file:list($var:pathResources, true())
    where contains($resource, ".xml")
    order by $resource
    return
      concat($var:pathResources, $resource)
  let $csvData := 
    if ($var:metadataCSV)
    then 
      for $csv in tokenize($var:metadataCSV)
      return
        csv:doc($csv, map{
        "header": true(),
        "separator": $var:separator
})
    else ()
  let $resources :=
    if ($var:metadataMapping != "")
    then
      if ($csvData != "")
      then ($resourcesXML, $var:metadataMapping, $csvData)
      else ($resourcesXML, $var:metadataMapping)
    else $resourcesXML
  let $paths :=
    (
      for $path in $resourcesXML return substring-after($path, "/TEI"),
      if ($var:metadataMapping != "") then concat("dots/", functx:substring-after-last($var:metadataMapping, "/dots")) else (),
      if ($csvData != "") 
      then 
        for $csv in tokenize($var:metadataCSV)
        return 
          concat("dots/", functx:substring-after-last($csv, "/dots"))
      else ()
    )
  return
    db:create($var:dbName, $resources, $paths, map {
      "ftindex": true(),
      "updindex": true(),
      "stemming": true(),
      "language": if ($var:language) then $var:language else "fr"
    })
};
