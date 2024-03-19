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
      <metadatas>{
        for $metadata at $pos in $collections/node()/name()
        group by $metadata
        return
          if ($pos = 1)
          then $metadata
          else concat("| ", $metadata)
      }</metadatas>
    let $documents := db:get($dbName, $G:resourcesRegister)//document
    let $countDocuments := count($documents)
    let $metadatasDoc :=
      <metadatas>{
        for $metadata at $pos in $documents/node()/name()
        group by $metadata
        return
          if ($pos = 1)
          then $metadata
          else concat("| ", $metadata)
      }</metadatas>
    let $fragments := 
      <fragment>{
        for $frag at $pos in db:get($dbName, $G:fragmentsRegister)//fragment
        let $citeType := $frag/@citeType
        group by $citeType 
        let $countFrag := count($frag)
        let $level := normalize-space($frag[1]/@level)
        return
          if ($pos = 1)
          then concat(
"- type '", $citeType, "' : ", $countFrag, " (level ", $level, ")")
          else
            concat("
- type '", $citeType, "' : ", $countFrag, " (level ", $level, ")")
      }</fragment>
    let $countFragments := count($fragments)
    let $metadatasFrag :=
      <metadata>{
        for $metadata at $pos in db:get($dbName, $G:fragmentsRegister)//fragment/node()/name()
        group by $metadata
        return
          if ($pos = 1)
          then $metadata
          else concat("| ", $metadata)
      }</metadata>
    return
      (concat("
Votre projet DoTS :
---------------
Projet : ", normalize-space($project), "
Nom de la base de données : ", $dbName, "
Collections : ", $countCollections, "
Métadonnées de collections : ", $metadatasColl, "
Documents : ", $countDocuments, "
Métadonnées de documents : ", <sequence>{$metadatasDoc}</sequence>, "
Fragments :
", $fragments, "
Métadonnées de fragments : ", $metadatasFrag, "
"
))

      (: <log>
        <project>{normalize-space($project)}</project>
        <mapping>{$mapping}</mapping>
        <collections>{$countCollections}</collections>
        <collectionsMetadata>{$metadatasColl}</collectionsMetadata>
        <documents>{$countDocuments}</documents>
        <documentsMetadata>{$metadatasDoc}</documentsMetadata>
        <fragments>{$fragments}</fragments>
        <fragmentsMetadata>{$metadatasFrag}</fragmentsMetadata>
      </log> :)
  return
    $log
    (: let $path := concat($G:webapp, $G:dots, "/.log/")
    let $logFileName := concat("log_", $project, "_", current-dateTime(), ".xml")
    return
      if (file:exists($path))
      then
        file:write(concat($path, $logFileName), $log)
      else
        (
          file:create-dir($path),
          file:write(concat($path, $logFileName), $log)
        ) :) 
};

(: declare function dots.log:csvResume($dbName) {
  let $project := db:get($dbName, $G:resourcesRegister)//*:collection[not(@parentIds)]
  let $content :=
    <csv>
      <record>
        <Project>{normalize-space($project)}</Project>
        <DbName>{$dbName}</DbName>
      </record>
    </csv>
  return
    csv:serialize($content, map {"header": true(), "separator": "|"})
}; :)


  
  