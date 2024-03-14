xquery version "3.1";

module namespace dots.log = "https://github.com/chartes/dots/log";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

(: declare variable $dbName external; :)

declare function dots.log:log($dbName) {
  let $project := db:get($dbName, $G:resourcesRegister)//collection[not(@parentIds)]
  let $log :=
    let $collections := db:get($dbName, $G:resourcesRegister)//collection[@parentIds]
    let $countCollections := count($collections)
    let $metadatasColl :=
      for $metadata in $collections/node()/name()
      group by $metadata
      order by $metadata
      return
        <metadata>{$metadata}</metadata>
    let $documents := db:get($dbName, $G:resourcesRegister)//document
    let $countDocuments := count($documents)
    let $metadatasDoc :=
      for $metadata in $documents/node()/name()
      group by $metadata
      order by $metadata
      return
        <metadata>{$metadata}</metadata>
    let $fragments := db:get($dbName, $G:fragmentsRegister)//fragment
    let $countFragments := count($fragments)
    let $metadatasFrag :=
      for $metadata in $fragments/node()/name()
      group by $metadata
      order by $metadata
      return
        <metadata>{$metadata}</metadata>
    return
      <log>
        <project>{normalize-space($project)}</project>
        <collections>{$countCollections}</collections>
        <collectionsMetadata>{$metadatasColl}</collectionsMetadata>
        <documents>{$countDocuments}</documents>
        <documentsMetadata>{$metadatasDoc}</documentsMetadata>
        <fragments>{$countFragments}</fragments>
        <fragmentsMetadata>{$metadatasFrag}</fragmentsMetadata>
      </log>
  return
    let $path := concat($G:webapp, $G:dots, "/.log/")
    let $logFileName := concat("log_", $project, "_", current-dateTime(), ".xml")
    return
      if (file:exists($path))
      then
        file:write(concat($path, $logFileName), $log)
      else
        (
          file:create-dir($path),
          file:write(concat($path, $logFileName), $log)
        ) 
};  
  