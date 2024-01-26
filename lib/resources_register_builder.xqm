xquery version "3.1";

(:~  
: Ce module permet de créer un fichier de configuration d'un projet / d'une collection. Ce document sert ensuite pour le routeur dots. Spécifiquement, le rôle de ce module est de créer le document de configuration, en y intégrant toutes les collections et ressources, avec leurs métadonnées OBLIGATOIRES (title, id, type, totalItems etc.)
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-25
: @version  1.0
: @todo pour l'ajout de @citeType: utiliser la fonction fn:normalize-unicode() pour enlever les diacritics
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib";

import module namespace functx = 'http://www.functx.com';

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace dots.fragments = "https://github.com/chartes/dots/lib" at "fragments_register_builder.xqm";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~  
: Cette fonction permet de construire un document XML de configuration (servant ensuite au routeur DoTS) à ajouter à la base de données XML.
: @return document XML
: @param $path chaîne de caractères. Pour lancer cette fonction, la valeur de ce paramètre est vide ("") (cet argument est nécessaire pour d'autres fonctions appelés par dots.lib:create_config)
: @param $counter nombre entier. Par défaut, ce nombre est de 0. Il est ensuite utilisé pour définir la valeur d'attribut @level d'un <member/> (cet argument est nécessaire pour d'autres fonctions appelés par dots.lib:create_config).
: @see project.xql;cc:getMetadata
: @see project.xql;cc:members
:)
declare updating function dots.lib:create_config($dbName as xs:string, $topCollectionId as xs:string) {
  let $countChild := 
    let $countDotsData := if (db:get($dbName, $G:metadata)) then 1 else 0
    let $count := count(db:dir($dbName, ""))
    return
      $count - $countDotsData
  let $content :=
    <resourcesRegister    
      xmlns:dct="http://purl.org/dc/terms/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
    >
      {dots.lib:getMetadata()}
      <member>
        <collection dtsResourceId="{$topCollectionId}" totalChildren="{$countChild}">{
          dots.lib:getCollectionMetadata($dbName, $topCollectionId)
        }</collection>
        {
          dots.lib:collections($dbName, $topCollectionId),
          dots.lib:document($dbName, $topCollectionId)
        }
      </member>
    </resourcesRegister>
  return
    (
      (:dots.switcher:createSwitcher($dbName, $topCollectionId), :)
      if (db:exists($dbName, $G:resourcesRegister))
      then 
        let $dots := db:get($dbName, $G:resourcesRegister)
        return
        (
          replace value of node $dots//dct:modified with current-dateTime(),
          replace node $dots//member with $content//member
        )
      else 
          (
            db:put($dbName, $content, $G:resourcesRegister)
          ),
      dots.fragments:createDocumentRegister($dbName)
    )
};

(:~ 
: Cette fonction se contente de construire l'en-tête <configMetadata/> du fichier de configuration
:)
declare function dots.lib:getMetadata() {
  <metadata>
    <dct:created>{current-dateTime()}</dct:created>
    <dct:modified>{current-dateTime()}</dct:modified>
  </metadata>
};

(:~ 
: Cette fonction récursive permet de recenser les collections et les resources d'une base de données XML 
: et de renvoyer vers les fonctions idoines pour construire le contenu du fichier de configuration.
: @param $path chaîne de caractères. Pour lancer cette fonction, la valeur de ce paramètre est vide ("")
: @param $counter nombre entier. Par défaut, ce nombre est de 0. Il est ensuite utilisé pour définir la valeur d'attribut @level d'un <member/>
: @see create_config.xql;cc:collection
: @see create_config.xql;cc:resource
:)
declare function dots.lib:collections($bdd as xs:string, $idProject as xs:string) {
  let $list_collections :=
    let $collections :=
      for $document in db:open($bdd)/tei:TEI 
      let $dbPath := db:path($document)
      let $base_path := functx:substring-before-last($dbPath, "/") 
      group by $base_path 
      let $c := count(tokenize($base_path, "/"))
      return
        <path>
          <complet_path>{$base_path}</complet_path>
          <nbre_collection>{$c}</nbre_collection>
        </path>
    return
      $collections
  return
    let $collectionsWithDuplicate :=
      for $collection in $list_collections
      let $nbre_collection := $collection/nbre_collection
      return
        if ($nbre_collection = 1)
        then
          let $path := $collection/complet_path
          let $totalChildren := count(db:dir($bdd, $path))
          return
            <collection dtsResourceId="{$path}" totalChildren="{$totalChildren}" parentIds="{$idProject}">{
                dots.lib:getCollectionMetadata($bdd, $path)
              }</collection>
        else
          let $splitCollections := tokenize($collection/complet_path, "/")
          return
            for $numCollection in 1 to $nbre_collection
            let $dtsResourceId := $splitCollections[$numCollection]
            let $path :=
              <path>{
                for $p in 1 to $numCollection
                return
                  concat($splitCollections[$p], "/")
              }</path>
            let $totalChildren := count(db:dir($bdd, replace($path, " ", "")))
            let $parent := 
              if ($splitCollections[$numCollection - 1])
              then $splitCollections[$numCollection - 1]
              else $idProject
            return
              <collection dtsResourceId="{$dtsResourceId}" totalChildren="{$totalChildren}" parentIds="{$parent}">{
                dots.lib:getCollectionMetadata($bdd, $dtsResourceId)
              }</collection>
    return
      for $goodCollection in $collectionsWithDuplicate
      let $id := $goodCollection/@dtsResourceId
      group by $id
      return
        $goodCollection[1]
};

(:~ 
: Cette fonction permet de construire l'élément <member/> correspondant à une resource, avec les métadonnées obligatoires: @id, @type, title, totalItems (à compléter probablement)
: @param $path chaîne de caractères.
: @param $counter nombre entier. Il est utilisé pour définir la valeur d'attribut @level d'un <member/>
:)
declare function dots.lib:document($bdd as xs:string, $idProject as xs:string) {
  for $document in db:get($bdd)/tei:TEI
  let $path := db:path($document)
  let $dtsResourceId := 
    if ($document/@xml:id)
    then $document/@xml:id
    else
      functx:substring-after-last($path, "/")
  let $maxCiteDepth := count($document//tei:refsDecl//tei:citeStructure)
  let $parentIds := 
    let $path := functx:substring-before-last($path, "/")
    return
      if (contains($path, "/"))
      then functx:substring-after-last($path, "/")
      else $path
  return
    if ($document)
    then
      <document dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$parentIds}">{
        dots.lib:getDocumentMetadata($bdd, $document, $dtsResourceId)
      }</document>
    else ()
};

declare function dots.lib:getDocumentMetadata($bdd as xs:string, $doc, $dtsResourceId as xs:string) {
  let $metadataMap := db:get($G:dots, $G:metadataMapping)//mapping
  let $externalMetadataMap := db:get($bdd)/metadataMap/mapping
  return
    for $metadata in if ($externalMetadataMap) then $externalMetadataMap/node()[@scope = "document"] else $metadataMap/node()[@scope = "document"]
    return
      if ($metadata/@resourceId = "all")
      then 
        let $key := $metadata/name()
        return
          element {$key} { concat($metadata/@prefix, $metadata, $metadata/@suffix) }
      else
        if ($metadata/@xpath)
        then
          let $metadataName := $metadata/name()
          let $xpath := $metadata/@xpath
          let $query := concat('
            declare default element namespace "http://www.tei-c.org/ns/1.0";',
            $xpath)
          let $valueQuery := xquery:eval($query, map {"": $doc})
          return
            if (normalize-space($valueQuery) != "")
            then element {$metadataName} {normalize-space($valueQuery)}
            else ()
        else
          let $csv := db:get($bdd, normalize-space($metadata/@source))//*:csv
          let $findIdInCSV := normalize-space($metadata/@resourceId)
          let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $dtsResourceId]]       
          return
            if ($record and $metadata) 
            then dots.lib:createContent($metadata, $record)
            else ()
};

declare function dots.lib:createContent($itemDeclaration, $record) {
  let $key := $itemDeclaration/name()
  let $element := $itemDeclaration/@value
  let $value := 
    if ($record/node()[name() = $element] != "")
    then
      concat($itemDeclaration/@prefix, $record/node()[name() = $element], $itemDeclaration/@suffix)
    else ()
  let $subKey := $itemDeclaration/@key
  let $type := $itemDeclaration/@type
  return
    if ($value) 
    then 
      element {$key} {
        if ($type) then attribute { "type" } { $type } else (),
        if ($subKey) then attribute { "key" } { $subKey } else (),
        $value
      } 
    else 
      ()
};

(:~ 
: Cette fonction permet de construire l'élément <member/> correspondant à une collection, avec les métadonnées obligatoires: @id, @type, title, totalItems (à compléter probablement)
: @param $path chaîne de caractères.
: @param $counter nombre entier. Il est utilisé pour définir la valeur d'attribut @level d'un <member/>
: @todo revoir l'ajout des métadonnées d'une collection. 
:)
declare function dots.lib:collection($bdd as xs:string, $idProject as xs:string, $collection as xs:string, $path as xs:string) {
  let $totalItems := count(db:dir($bdd, $collection))
  let $parent := 
    if ($path = "") 
    then $idProject 
    else 
      if (contains($path, "/"))
      then
        functx:substring-after-last($path, "/")
      else $path
  return
    <collection dtsResourceId="{$collection}" totalChildren="{$totalItems}" parentIds="{$parent}">{
      dots.lib:getCollectionMetadata($bdd, $collection)
    }</collection>
};

declare function dots.lib:getCollectionMetadata($bdd as xs:string, $collection as xs:string) {
  let $metadataMap :=  db:get($bdd, $G:metadata)//metadataMap
  return
    if ($metadataMap)
    then
      let $metadatas := 
        for $metadata in $metadataMap//mapping/node()[@scope = "collection"]
        let $getResourceId := $metadata/@resourceId
        let $csv := db:get($bdd, normalize-space($metadata/@source))//*:csv
        let $findIdInCSV := normalize-space($metadata/@resourceId)
        let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $collection]]       
        return
          if ($metadata/@resourceId = "all")
          then 
            let $key := $metadata/name()
            return
              element {$key} { concat($metadata/@prefix, $metadata, $metadata/@suffix) }
          else
            if ($record and $metadata) 
            then dots.lib:createContent($metadata, $record)
            else ()
      return
        if ($metadatas/name() = "dc:title")
        then $metadatas
        else 
          (
            <dc:title>{$collection}</dc:title>,
            $metadatas
          )
    else <dc:title>{$collection}</dc:title>
};






