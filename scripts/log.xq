xquery version "3.1";

module namespace dots.log = "https://github.com/chartes/dots/log";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";

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
        if (db:get($dbName, $G:fragmentsRegister)//fragment)
        then
          for $frag at $pos in db:get($dbName, $G:fragmentsRegister)//fragment
          let $citeType := 
            if ($frag/@citeType != "")
            then $frag/@citeType
            else "undefined citeType"
          group by $citeType 
          let $countFrag := count($frag)
          let $level := normalize-space($frag[1]/@level)
          return
            concat("- type '", $citeType, "' : ", $countFrag, " (level ", $level, ")")
        else "0"
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
Projet : ", normalize-space($project/dc:title), "
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
  return
    $log
};