xquery version "3.1";

(:~  
: Ce module permet, au besoin, de mettre à jour le registre "/dots/resources_register.xml" pour:
: - ajouter de nouvelle(s) collection(s) et de spécifier les documents qui lui / leur appartiennent
: - et de gérer ainsi les cas de document(s) qui appartiennent à plusieurs collections
: @author École nationale des chartes - Philippe Pons
: @description ce module fonctionne en s'appuyant sur un tableur csv qui doit respecter notre modèle
: @since 2024-01-16
: @version  1.0
: @todo: rédiger la documentation de ce module
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib";

declare namespace dots = "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare updating function dots.lib:handle($srcPath) {
  let $source := csv:doc($srcPath, map{
        "header": true(),
        "separator": $G:separator
})
  return
    (
      dots.lib:countResourcesToAddToCollections($source/csv),
      for $collections in $source/csv/record
      let $dbName := $collections/dbName
      let $switcherDots := dots.lib:switcherDots($collections)
      let $collectionsInResourcesRegister := dots.lib:collectionsInResourcesRegister($collections)
      return
        (
          insert node $switcherDots as last into db:get($G:dots, $G:dbSwitcher)//dots:member,
          insert node $collectionsInResourcesRegister into db:get($dbName, $G:resourcesRegister)//dots:member, 
          dots.lib:documentsInResourcesRegister($collections)
        ) 
    )
};

declare function dots.lib:switcherDots($record as element(record)) {
  let $dbName := $record/dbName
  let $collection_dtsResourceId := $record/collection_dtsResourceId
  return
    <collection dtsResourceId="{$collection_dtsResourceId}" dbName="{$dbName}"/>
};

declare function dots.lib:collectionsInResourcesRegister($record as element(record)) {
  let $dtsResourceId := $record/collection_dtsResourceId
  let $documents := 
    for $doc in tokenize($record/documents_dtsResourceId, "[\|]")
    return
      $doc
  let $totalChildren := count($documents)
  let $parentIds :=
    if ($record/parentIds != "")
    then
      $record/parentIds
    else
      $record/dbName
  let $title := $record/dc_title
  let $metadata := dots.lib:getMetadata($record)
  return
    <collection dtsResourceId="{$dtsResourceId}" totalChildren="{$totalChildren}" parentIds="{$parentIds}">
      <dc:title>{normalize-space($title)}</dc:title>
      {$metadata}
    </collection>
};

declare updating function dots.lib:documentsInResourcesRegister($record as element(record)) {
  let $dbName := $record/dbName
  let $collection_dtsResourceId := $record/collection_dtsResourceId
  return
    let $documents := $record/documents_dtsResourceId
    return
      for $document in tokenize($documents, "[\|]")
      let $docInRegister := db:get($dbName, $G:resourcesRegister)//dots:member/dots:document[@dtsResourceId = normalize-space($document)]
      let $parentIds := $docInRegister/@parentIds
      let $newParentIds := concat($docInRegister/@parentIds, " ", $collection_dtsResourceId)
      return
        replace value of node $parentIds with $newParentIds
};

declare function dots.lib:getMetadata($record as element(record)) {
  for $metadata in $record/node()[position() > 5]
  let $elementName := $metadata/name()
  return
    element {$elementName} {normalize-space($metadata)}
};

declare updating function dots.lib:countResourcesToAddToProject($source as element(csv)) {
  let $dbName := $source/record[1]/dbName
  let $countResources := count($source/record[parentIds = ""])
  let $getProject := db:get($dbName, $G:resourcesRegister)//dots:member/dots:collection[@dtsResourceId = $dbName]
  let $totalChildren := $getProject/@totalChildren
  let $newTotalChildren := $totalChildren + $countResources
  return
    replace value of node $totalChildren with $newTotalChildren
};

declare updating function dots.lib:countResourcesToAddToCollections($source as element(csv)) {
  let $dbName := $source/record[1]/dbName
  let $getRegister := db:get($dbName, $G:resourcesRegister)//dots:member
  for $record in $source/record
  let $parentIds := $record/parentIds
  group by $parentIds
  return
    for $parentId in $parentIds
    let $countResourcesInCollection := count($source/record[parentIds = $parentId])
    let $getCollection := $getRegister/dots:collection[@dtsResourceId = (if ($parentId) then $parentId else $dbName)]
    let $totalChildren := $getCollection/@totalChildren
    let $newTotalChildren := $countResourcesInCollection + $totalChildren
    return
      if ($getCollection)
      then
        replace value of node $totalChildren with $newTotalChildren
      else ()
};


