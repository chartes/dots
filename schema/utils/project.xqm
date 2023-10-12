xquery version "3.1";

(:~  
: Ce module permet de créer un fichier de configuration d'un projet / d'une collection. Ce document sert ensuite pour le routeur dots. Spécifiquement, le rôle de ce module est de créer le document de configuration, en y intégrant toutes les collections et ressources, avec leurs métadonnées OBLIGATOIRES (title, id, type, totalItems etc.)
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-25
: @version  1.0
: @todo pour l'ajout de @citeType: utiliser la fonction fn:normalize-unicode() pour enlever les diacritics
:)

module namespace cc = "https://github.com/chartes/dots/schema/utils/cc";

import module namespace G = "https://github.com/chartes/dots/globals" at "../../globals.xqm";
import module namespace ccg = "https://github.com/chartes/dots/schema/utils/ccg" at "root.xqm";
import module namespace docR = "https://github.com/chartes/dots/schema/utils/docR" at "documentRegister.xqm";

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
declare updating function cc:create_config($idProject as xs:string, $dbName as xs:string, $title as xs:string, $path as xs:string) {
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
      {cc:getMetadata()},
      <member>
        <collection dtsResourceId="{$idProject}" totalChildren="{$countChild}">
          <dc:title>{$title}</dc:title>
        </collection>
        {cc:members($dbName, $idProject, $path)}
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
declare function cc:members($bdd as xs:string, $idProject as xs:string, $path as xs:string) {
  for $dir in db:dir($bdd, $path)
  where not(contains($dir, $G:metadata))
  order by $dir
  return
    if ($dir[name() = "resource"])
    then cc:document($bdd, $dir, $path)
    else
      (
        if ($dir = "dots") then () else cc:collection($bdd, $idProject, $dir, $path),
        cc:members($bdd, $idProject, $dir)
      )
};

(:~ 
: Cette fonction permet de construire l'élément <member/> correspondant à une resource, avec les métadonnées obligatoires: @id, @type, title, totalItems (à compléter probablement)
: @param $path chaîne de caractères.
: @param $counter nombre entier. Il est utilisé pour définir la valeur d'attribut @level d'un <member/>
:)
declare function cc:document($bdd as xs:string, $resource as xs:string, $path as xs:string) {
  let $doc := db:get($bdd, concat($path, "/", $resource))/tei:TEI
  let $dtsResourceId := 
    if ($doc/@xml:id)
    then normalize-space($doc/@xml:id)
    else db:node-id($doc)
  let $title := normalize-space($doc//tei:titleStmt/tei:title[1])
  let $maxCiteDepth := count($doc//tei:refsDecl//tei:citeStructure)
  return
    if ($doc)
    then
      <document dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{if ($path) then $path else $bdd}">{
        cc:getDocumentMetadata($bdd, $doc)
      }</document>
    else ()
};

declare function cc:getDocumentMetadata($bdd as xs:string, $doc) {
  let $metadataMap := db:get($G:dots, $G:metadataMapping)//mapping
  let $externalMetadataMap := db:get($bdd, $G:metadata)/metadataMap/mapping
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
      if ($valueQuery)
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
  let $parent := if ($path = "") then $idProject else $path
  return
    <collection dtsResourceId="{$collection}" totalChildren="{$totalItems}" parentIds="{$parent}">{
      cc:getCollectionMetadata($bdd, $collection)
    }</collection>
};

declare function cc:getCollectionMetadata($bdd as xs:string, $collection as xs:string) {
  let $metadataMap :=  db:get($bdd, $G:metadata)/metadataMap
  for $metadata in $metadataMap//mapping/node()[@scope = "collection"]
  let $getResourceId := $metadata/@resourceId
  let $source := db:get($bdd, normalize-space($metadata/@source))//*:record[node()[name() = $getResourceId] = $collection]
  let $metadataName := $metadata/name()
  let $contentName := $metadata/@content
  let $content := normalize-space($source/node()[name() = $contentName])
  return
    element {$metadataName} {$content}
};






