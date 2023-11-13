xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de créer sa base de données BaseX
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-11
: @version  1.0
:)

module namespace dbc = "https://github.com/chartes/dots/db/dbc";

import module namespace functx = "http://www.functx.com";

declare variable $dbc:resourceId := "Littérature";

declare variable $dbc:dbName := "litterature";

declare variable $dbc:pathResources := "/home/ppons/Documents/Work/dots_corpus/CORPUS-DEMO_DoTS/cas_3/TEI/";

declare variable $dbc:metadataMapping := "/home/ppons/Documents/Work/dots_corpus/CORPUS-DEMO_DoTS/cas_3/dots/metadata_mapping.xml";

declare variable $dbc:metadataTSV := "/home/ppons/Documents/Work/dots_corpus/CORPUS-DEMO_DoTS/cas_3/dots/litterature_metadata.csv";

declare variable $dbc:separator := "	";

declare variable $dbc:language := "fr";

declare updating function dbc:dbCreate() {
  let $resourcesXML :=
    for $resource in file:list($dbc:pathResources, true())
    where contains($resource, ".xml")
    order by $resource
    return
      concat($dbc:pathResources, $resource)
  let $tsv := 
    if ($dbc:metadataTSV)
    then csv:doc($dbc:metadataTSV, map{
  "header": true(),
  "separator": $dbc:separator
})
    else ()
  let $resources :=
    if ($dbc:metadataMapping != "")
    then
      if ($tsv != "")
      then ($resourcesXML, $dbc:metadataMapping, $tsv)
      else ($resourcesXML, $dbc:metadataMapping)
    else $resourcesXML
  let $paths :=
    (
      for $path in $resourcesXML return substring-after($path, "/TEI"),
      if ($dbc:metadataMapping != "") then concat("dots/", functx:substring-after-last($dbc:metadataMapping, "/dots")) else (),
      if ($tsv != "") then concat("dots/", functx:substring-after-last($dbc:metadataTSV, "/dots")) else ()
    )
  return
    db:create($dbc:dbName, $resources, $paths, map {
      "ftindex": true(),
      "updindex": true(),
      "stemming": true(),
      "language": $dbc:language
    })
};
