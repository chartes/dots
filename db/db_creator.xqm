xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de créer sa base de données BaseX
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)

module namespace dbc = "https://github.com/chartes/dots/db/dbc";

import module namespace functx = "http://www.functx.com";

declare variable $dbc:resourceId := "ENCPOS";

declare variable $dbc:dbName := "ENCPOS";

declare variable $dbc:pathResources := "/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/TEI/";

declare variable $dbc:metadataMapping := "/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/metadata_mapping.xml";

declare variable $dbc:metadataCSV := "
/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/encpos.tsv
/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/titles.csv
";

declare variable $dbc:separator := "	";

declare variable $dbc:language := "fr";

declare updating function dbc:dbCreate() {
  let $resourcesXML :=
    for $resource in file:list($dbc:pathResources, true())
    where contains($resource, ".xml")
    order by $resource
    return
      concat($dbc:pathResources, $resource)
  let $csvData := 
    if ($dbc:metadataCSV)
    then 
      for $csv in tokenize($dbc:metadataCSV)
      return
        csv:doc($csv, map{
        "header": true(),
        "separator": $dbc:separator
})
    else ()
  let $resources :=
    if ($dbc:metadataMapping != "")
    then
      if ($csvData != "")
      then ($resourcesXML, $dbc:metadataMapping, $csvData)
      else ($resourcesXML, $dbc:metadataMapping)
    else $resourcesXML
  let $paths :=
    (
      for $path in $resourcesXML return substring-after($path, "/TEI"),
      if ($dbc:metadataMapping != "") then concat("dots/", functx:substring-after-last($dbc:metadataMapping, "/dots")) else (),
      if ($csvData != "") 
      then 
        for $csv in tokenize($dbc:metadataCSV)
        return 
          concat("dots/", functx:substring-after-last($csv, "/dots"))
      else ()
    )
  return
    db:create($dbc:dbName, $resources, $paths, map {
      "ftindex": true(),
      "updindex": true(),
      "stemming": true(),
      "language": $dbc:language
    })
};
