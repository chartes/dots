xquery version "4.0";

(:~  
: The resources registry built by the functions below optimizes DTS API responses. It provides a precomputed hierarchical structure of collections and documents, facilitating efficient navigation and retrieval of textual resources. By organizing metadata and structural information in advance, it enhances the responsiveness and interoperability of the DTS implementation.
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-25
: @version  1.0
: @todo pour l'ajout de @citeType: utiliser la fonction fn:normalize-unicode() pour enlever les diacritics
:)
module namespace resources = "backend/resources_register_builder";

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace fragments = "backend/fragments_register_builder";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dots = "https://github.com/chartes/dots/";

(:~  
: This function generates the document resources_register.xml document that inventories all collections and documents in the given database. It also adds metadata and invokes the fragment registry creation. 
: @param $dbName (xs:string) The name of the XML database
: @param $idProject (xs:string) The identifier of the project.
: @return An XML document representing the resources register is stored in the database.
:)
declare updating function resources:createResourcesRegister(
  $dbName as xs:string,
  $idProject as xs:string
) {
  let $csv-coll := resources:getCSV-map($dbName, "collection")
  let $csv-doc := resources:getCSV-map($dbName, "document")
  let $countChild := 
    let $countDotsData := if (db:get($dbName, $G:metadata)) then 1 else 0
    let $count := count(db:dir($dbName, ""))
    return
      $count - $countDotsData
  let $content :=
    <resourcesRegister>
      {
        let $mapping := db:get($dbName, $G:metadata)/metadataMap
        return
          if ($mapping)
          then 
            for $prefix in in-scope-prefixes($mapping)
            where $prefix != ""
            where $prefix != "dc"
            where $prefix != "xml"
            let $ns := namespace-uri-for-prefix($prefix, $mapping)
            return
              namespace {$prefix} {$ns}
          else 
            (
              namespace {"dc"} {"http://purl.org/dc/elements/1.1/"}
            )
      }
      {resources:getMetadata()}
      <member>
        <collection dtsResourceId="{$idProject}" totalChildren="{$countChild}">{
          resources:getCollectionMetadata($dbName, $idProject, $csv-coll),
          resources:getDotsProjectName($idProject)
        }</collection>
        {
          resources:collections($dbName, $idProject, $csv-coll),
          resources:document($dbName, $idProject, $csv-doc)
        }
      </member>
    </resourcesRegister>
  return
    (
      db:put($dbName, $content, $G:resourcesRegister),
      fragments:createFragmentsRegister($dbName)
    )
};

(:~ 
: Generates a <metadata> element with creation and modification timestamps.
: @return An XML fragment containing <dct:created> and <dct:modified> elements
:)
declare function resources:getMetadata() {
  <metadata>
    <dct:created>{current-dateTime()}</dct:created>
    <dct:modified>{current-dateTime()}</dct:modified>
  </metadata>
};

(:~  
: Recursively collects all collections in the database and generates a <collection> XML structure with relevant metadata.
: @param $dbName (xs:string) The name of the XML database
: @param $idProject (xs:string) The identifier of the project.
: @return A sequence of <collection> elements
:)
declare function resources:collections(
  $dbName as xs:string, 
  $idProject as xs:string,
  $csv) {
  let $list_collections :=
    for $document in db:get($dbName)/tei:TEI
    let $filePath := db:path($document)
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
    let $collectionsWithDuplicate :=
      for $collection in $list_collections
      let $nbre_collection := $collection/nbre_collection
      return
        if ($nbre_collection = 1)
        then
          let $path := $collection/complet_path
          let $totalChildren := count(db:dir($dbName, $path))
          return
            <collection dtsResourceId="{$path}" totalChildren="{$totalChildren}" parentIds="{$idProject}">{
                resources:getCollectionMetadata($dbName, $path, $csv),
                resources:getDotsProjectName($idProject)
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
            let $totalChildren := count(db:dir($dbName, replace($path, " ", "")))
            let $parent := 
              if ($splitCollections[$numCollection - 1])
              then $splitCollections[$numCollection - 1]
              else $idProject
            return
              <collection dtsResourceId="{$dtsResourceId}" totalChildren="{$totalChildren}" parentIds="{$parent}">{
                resources:getCollectionMetadata($dbName, $dtsResourceId, $csv),
                resources:getDotsProjectName($idProject)
              }</collection>
    return
      for $goodCollection in $collectionsWithDuplicate
      let $id := $goodCollection/@dtsResourceId
      where $id != "dots"
      group by $id
      return
        $goodCollection[1]
};

(:~ 
: Creates a <document> element for each TEI document found in the database, including metadata and citation depth information.
: @param $dbName (xs:string) The name of the XML database
: @param $idProject (xs:string) The identifier of the project.
: @return An XML fragment containing document metadata
:)
declare %private function resources:document(
  $dbName as xs:string,
  $idProject as xs:string,
  $csv
) {
  for $document in db:get($dbName)/tei:TEI
  let $path := db:path($document)
  let $dtsResourceId := 
    if ($document/@xml:id)
    then $document/@xml:id
    else
      if (contains($path, "/"))
      then functx:substring-after-last($path, "/")
      else $path
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  let $parentIds := 
    if (contains($path, "/"))
    then
      let $path := functx:substring-before-last($path, "/")
      return
        if (contains($path, "/"))
        then functx:substring-after-last($path, "/")
        else 
          $path
    else $idProject
  where $document
  return
    <document dtsResourceId="{$dtsResourceId}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$parentIds}">{
      resources:getDocumentMetadata($dbName, $document, $dtsResourceId, $csv),
      resources:getDotsProjectName($idProject)
    }</document>
};

(:~  
: Extracts metadata for a document based on predefined mappings and external metadata sources.
: @param $dbName (xs:string) The name of the XML database.
: @param $doc (element(tei:TEI)) The XML-TEI document node.
: @param $dtsResourceId (xs:string) The document identifier.
: @return A sequence containing document metadata elements
:)
declare function resources:getDocumentMetadata(
  $dbName as xs:string,
  $doc as element(tei:TEI),
  $dtsResourceId as xs:string,
  $csv-map
) {
  let $metadataMap := db:get($G:dots, $G:metadataMapping)//mapping
  let $externalMetadataMap := db:get($dbName)/metadataMap/mapping
  let $dcTitle :=
    if ($externalMetadataMap and $externalMetadataMap/dc:title[@scope="document"])
    then ()
    else <dc:title>{normalize-space($doc//tei:titleStmt/tei:title[@type = 'main' or position() = 1])}</dc:title>
  return
    (
      $dcTitle,
      for $metadata in if ($externalMetadataMap) then $externalMetadataMap/node()[@scope = "document"] else $metadataMap/node()[@scope = "document"][name() != "dc:title"]
      return
        if ($metadata/@resourceId = "all")
        then 
          let $key := $metadata/name()
          return
            element {$key} { 
              if ($metadata/@key) then attribute {"key"} {$metadata/@key},
              concat($metadata/@prefix, $metadata, $metadata/@suffix) 
            }
        else
          if ($metadata/@xpath)
          then
            let $metadataName := $metadata/name()
            let $xpath := $metadata/@xpath
            let $query := concat('
              declare default element namespace "http://www.tei-c.org/ns/1.0";',
              $xpath)
            let $valueQuery := xquery:eval($query, map {"": $doc})
            let $type := $metadata/@type
            let $key := $metadata/@key
            return
              if ($valueQuery != "")
              then 
                for $value in $valueQuery
                return
                  element {$metadataName} {
                    if ($type) then attribute { "type" } { $type } else (),
                    if ($key) then attribute { "key" } { $key } else (),
                    concat($metadata/@prefix, $value, $metadata/@suffix)
                  }
              else ()
          else
            let $source := functx:substring-after-last($metadata/@source, '/')
            let $csv-source := $csv-map($source)
            for $record in $csv-source($dtsResourceId)
            return
              resources:createContent($metadata, $record)
   )
};

(:~  
: Retrieves metadata for a collection from the metadata map
: @param $dbName (xs:string) The name of the XML database.
: @param $collection (xs:string) The collection identifier.
: @param $csv-map (map(*)) Map with CSV contents
: @return An XML fragment containing collection metadata.
:)
declare function resources:getCollectionMetadata(
  $dbName as xs:string, 
  $collection as xs:string, 
  $csv-map) {
  let $metadataMap :=  db:get($dbName, $G:metadata)//metadataMap/mapping
  return
    if ($metadataMap)
    then
      let $metadatas :=
        for $metadata in $metadataMap/node()[@scope = "collection"]
        return
          if ($metadata/@resourceId = "all")
          then 
            let $key := $metadata/name()
            return element {$key} { 
              if ($metadata/@key) then attribute {"key"} {$metadata/@key},
              if ($metadata != "") then concat($metadata/@prefix, $metadata, $metadata/@suffix) 
            }
          else 
            let $source := functx:substring-after-last($metadata/@source, '/')
            let $csv-source := $csv-map($source)
            return
              if (exists(map:get($csv-source, $collection)))
              then
                for $record in $csv-source($collection)
                return
                  resources:createContent($metadata, $record) 
              else
                ()
        let $title := if ($metadatas/descendant-or-self::dc:title) then () else <dc:title>{$collection}</dc:title>
        return ($title, $metadatas)
    else <dc:title>{$collection}</dc:title>
};

(:~  
 : Returns a map with all CSV contents from the specified database for which source paths exist.
 : @param $dbName (xs:string) The name of the XML database.
 : @return map
 :)
declare function resources:getCSV-map(
  $dbName as xs:string,
  $type as xs:string
) as map(*) {
  map:merge(
    let $sources := distinct-values(
      let $metadataMap := db:get($dbName, $G:metadata)/metadataMap/mapping
      for $metadata in $metadataMap/node()[@source][@scope = $type]
      return functx:substring-after-last($metadata/@source, "/")
    )
    for $source in $sources
    let $csv := head(db:get($dbName)//*:csv[contains(db:path(.), $source)])
    return map:entry(
      $source,
      map:merge(
        for $record in $csv/*:record
        return map:entry(
          $record/*:id,
          map:merge($record/* ! map:entry(name(.), data(.)))
        )
      )
    )
  )
};

(:~ 
: Generates a metadata element based on a given declaration and record.
: @param $itemDeclaration The XML node describing the metadata structure.
: @param $record The corresponding record from the database.
: @return An XML element with the extracted metadata value.
:)
declare function resources:createContent(
  $itemDeclaration,
  $csv-record as map(*)
) {
  let $key := $itemDeclaration/name()
  let $element := $itemDeclaration/@value
  let $value := (
    for $v in $csv-record($element)
    where $v
    return concat($itemDeclaration/@prefix, $v, $itemDeclaration/@suffix)
  )
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
: Creates a <dots:dotsProjectId> element for a given project.
: @param $projectName (xs:string) The name of the project.
: @return An XML element containing the project identifier.
:)
declare function resources:getDotsProjectName($projectName as xs:string) {
  <dots:dotsProjectId>{$projectName}</dots:dotsProjectId>
};


