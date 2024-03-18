xquery version "3.1";

module namespace dots.log = "https://github.com/chartes/dots/log";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare function dots.log:log($dbName) {
  let $project := db:get($dbName, $G:resourcesRegister)//collection[not(@parentIds)]
  let $log :=
    let $mapping := 
      if (db:get($dbName)/metadataMap/mapping)
      then "user"
      else "default"
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
    let $fragments := 
      for $frag in db:get($dbName, $G:fragmentsRegister)//fragment
      let $citeType := $frag/@citeType
      group by $citeType 
      let $countFrag := count($frag)
      let $level := normalize-space($frag[1]/@level)
      return
        <fragment>
          <citeType>{$citeType}</citeType>
          <number>{$countFrag}</number>
          <level>{$level}</level>
        </fragment>
    let $countFragments := count($fragments)
    let $metadatasFrag :=
      for $metadata in db:get($dbName, $G:fragmentsRegister)//fragment/node()/name()
      group by $metadata
      order by $metadata
      return
        <metadata>{$metadata}</metadata>
    return
      <log>
        <project>{normalize-space($project)}</project>
        <mapping>{$mapping}</mapping>
        <collections>{$countCollections}</collections>
        <collectionsMetadata>{$metadatasColl}</collectionsMetadata>
        <documents>{$countDocuments}</documents>
        <documentsMetadata>{$metadatasDoc}</documentsMetadata>
        <fragments>{$fragments}</fragments>
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
  