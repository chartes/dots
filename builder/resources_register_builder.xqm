xquery version "3.1";

(:~  
: Ce module permet de créer un fichier de configuration d'un projet / d'une collection. Ce document sert ensuite pour le routeur dots. Spécifiquement, le rôle de ce module est de créer le document de configuration, en y intégrant toutes les collections et ressources, avec leurs métadonnées OBLIGATOIRES (title, id, type, totalItems etc.)
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-25
: @version  1.0
: @todo pour l'ajout de @citeType: utiliser la fonction fn:normalize-unicode() pour enlever les diacritics
:)

module namespace cc = "https://github.com/chartes/dots/builder/cc";

import module namespace functx = 'http://www.functx.com';

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace ccg = "https://github.com/chartes/dots/builder/ccg" at "db_switch_builder.xqm";
import module namespace docR = "https://github.com/chartes/dots/builder/docR" at "fragments_register_builder.xqm";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~  
: Cette fonction permet de construire un document XML de configuration (servant ensuite au routeur DoTS) à ajouter à la base de données XML.
: @return document XML
: @param $path chaîne de caractères. Pour lancer cette fonction, la valeur de ce paramètre est vide ("") (cet argument est nécessaire pour d'autres fonctions appelés par cc:create_config)
: @param $counter nombre entier. Par défaut, ce nombre est de 0. Il est ensuite utilisé pour définir la valeur d'attribut @level d'un <member/> (cet argument est nécessaire pour d'autres fonctions appelés par cc:create_config).
: @see project.xql;cc:getMetadata
: @see project.xql;cc:members
:)
declare updating function cc:create_config($idProject as xs:string, $dbName as xs:string, $title as xs:string) {
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
      {cc:getMetadata()}
      <member>
        <collection dtsResourceId="{$idProject}" totalChildren="{$countChild}">
          <dc:title>{$title}</dc:title>
        </collection>
        {
          cc:collections($dbName, $idProject),
          cc:document($dbName, $idProject)
        }
      </member>
    </resourcesRegister>
  return
    (
      ccg:create_config($idProject, $dbName),
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
      docR:createDocumentRegister($dbName)
    )
};

(:~ 
: Cette fonction se contente de construire l'en-tête <configMetadata/> du fichier de configuration
:)
declare function cc:getMetadata() {
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
declare function cc:collections($bdd as xs:string, $idProject as xs:string) {
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
                cc:getCollectionMetadata($bdd, $path)
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
                cc:getCollectionMetadata($bdd, $dtsResourceId)
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
declare function cc:document($bdd as xs:string, $idProject as xs:string) {
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
        cc:getDocumentMetadata($bdd, $document)
      }</document>
    else ()
  (: let $doc := db:get($bdd, concat($path, "/", $resource))/tei:TEI
  let $dtsResourceId := 
    if ($doc/@xml:id)
    then $doc/@xml:id
    else $resource
  let $maxCiteDepth := count($doc//tei:refsDecl//tei:citeStructure)
  let $parentIds :=
    if ($path)
    then
      if (contains($path, "/"))
      then functx:substring-after-last($path, "/")
      else $path
    else $idProject
  return
    if ($doc)
    then
      <document dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$parentIds}">{
        cc:getDocumentMetadata($bdd, $doc)
      }</document>
    else () :)
};

declare function cc:getDocumentMetadata($bdd as xs:string, $doc) {
  let $metadataMap := db:get($G:dots, $G:metadataMapping)//mapping
  let $externalMetadataMap := db:get($bdd)/metadataMap/mapping
  return
    for $metadata in if ($externalMetadataMap) then $externalMetadataMap/node()[@scope = "document"] else $metadataMap/node()[@scope = "document"]
    where $metadata/@xpath
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
};

(:~ 
: Cette fonction permet de construire l'élément <member/> correspondant à une collection, avec les métadonnées obligatoires: @id, @type, title, totalItems (à compléter probablement)
: @param $path chaîne de caractères.
: @param $counter nombre entier. Il est utilisé pour définir la valeur d'attribut @level d'un <member/>
: @todo revoir l'ajout des métadonnées d'une collection. 
:)
declare function cc:collection($bdd as xs:string, $idProject as xs:string, $collection as xs:string, $path as xs:string) {
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
      cc:getCollectionMetadata($bdd, $collection)
    }</collection>
};

declare function cc:getCollectionMetadata($bdd as xs:string, $collection as xs:string) {
  let $metadataMap :=  db:get($bdd, $G:metadata)//metadataMap
  return
    if ($metadataMap)
    then
      let $metadatas := 
        for $metadata in $metadataMap//mapping/node()[@scope = "collection"]
        let $getResourceId := $metadata/@resourceId
        let $source := db:get($bdd, normalize-space($metadata/@source))//*:record[node()[name() = $getResourceId] = $collection]
        let $metadataName := $metadata/name()
        let $contentName := $metadata/@content
        let $content := normalize-space($source/node()[name() = $contentName])
        return 
          if ($content != "") 
          then element {$metadataName} {$content}
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






