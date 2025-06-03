xquery version '4.0' ;

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace fragments = "backend/fragments_register_builder";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $dbName := "encpos"; (: other possible values with your data :    "encpos", "theater", "cid" :)
declare variable $idProject := "ENCPOS"; (: other possible values with your data : "ENCPOS", "theater", "cid" :)

(:~  
: This function generates the document resources_register.xml document that inventories all collections and documents in the given database. It also adds metadata and invokes the fragment registry creation. 
: @param $dbName (xs:string) The name of the XML database
: @param $idProject (xs:string) The identifier of the project.
: @return An XML document representing the resources register is stored in the database.
:)
declare function local:createResourcesRegister(
  $dbName as xs:string,
  $idProject as xs:string
) {
  let $csv := local:getCSV-map($dbName, "document")

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
      {local:getMetadata()}
      <member>
        <collection dtsResourceId="{$idProject}" totalChildren="{$countChild}">{
          local:getCollectionMetadata($dbName, $idProject, $csv)
        }</collection>
        {
          local:document($dbName, $idProject, $csv)
        }
      </member>
    </resourcesRegister>
  return
    $content(: (
      db:put($dbName, $content, $G:resourcesRegister)
    ) :)
};

(:~ 
: Generates a <metadata> element with creation and modification timestamps.
: @return An XML fragment containing <dct:created> and <dct:modified> elements
:)
declare function local:getMetadata() {
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
declare function local:collections($dbName as xs:string, $idProject as xs:string) {
  let $list_collections :=
    let $collections :=
      for $document in db:get($dbName)/node()
      let $filePath := db:path($document)
      where not(contains($filePath, "metadata/"))
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
      let $csv-map := local:getCSV-map($dbName, "collection")
      for $collection in $list_collections
      let $nbre_collection := $collection/nbre_collection
      return
        if ($nbre_collection = 1)
        then
          let $path := $collection/complet_path
          let $totalChildren := count(db:dir($dbName, $path))
          return
            <collection dtsResourceId="{$path}" totalChildren="{$totalChildren}" parentIds="{$idProject}">{
                local:getCollectionMetadata($dbName, $path, $csv-map)
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
                local:getCollectionMetadata($dbName, $dtsResourceId, $csv-map)
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
declare %private function local:document(
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
      local:getDocumentMetadata($dbName, $document, $dtsResourceId, $csv)
    }</document>
};

(:~  
: Extracts metadata for a document based on predefined mappings and external metadata sources.
: @param $dbName (xs:string) The name of the XML database.
: @param $doc (element(tei:TEI)) The XML-TEI document node.
: @param $dtsResourceId (xs:string) The document identifier.
: @return A sequence containing document metadata elements
:)
declare function local:getDocumentMetadata(
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
    else <dc:title xpath="//titleStmt/title[@type = 'main' or position() = 1]" scope="document"/>
  return
    (
      for $metadata in if ($externalMetadataMap) then $externalMetadataMap/node()[@scope = "document"] else $metadataMap/node()[@scope = "document"]
      return
        if ($metadata/@resourceId = "all")
        then 
          let $key := $metadata/name()
          return
            element {$key} { 
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
            let $source := replace($metadata/@source, '\./', '')
            let $csv-source := $csv-map($source)
            (:
            let $SrcDocName := functx:substring-after-last($source, "/")
            let $SrcPath := db:list($dbName)[contains(., $SrcDocName)]
            let $csv := db:get($dbName, $SrcPath)/*:csv
            :)
            (: let $findIdInCSV := normalize-space($metadata/@resourceId) :)
             
            for $record in $csv-source($dtsResourceId)
            return
              local:createContent($metadata, $record)

            (: let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $dtsResourceId]]

            where ($record and $metadata)
            return
              local:createContent($metadata, $record) :)

   )
};

(:~ 
: Creates a <collection> element with metadata, parent relationships, and child count.
: @param $dbName (xs:string) The name of the XML database.
: @param $idProject (xs:string) The identifier of the project.
: @param $collection (xs:string) The collection identifier.
: @param $path (xs:string) The path of the collection.
: @return An XML element representing the collection
:)
declare %private function local:collection($dbName as xs:string, $idProject as xs:string, $collection as xs:string, $path as xs:string) {
  let $totalItems := count(db:dir($dbName, $collection))
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
      local:getCollectionMetadata($dbName, $collection)
    }</collection>
};

(:~  
: Retrieves metadata for a collection from the metadata map
: @param $dbName (xs:string) The name of the XML database.
: @param $collection (xs:string) The collection identifier.
: @param $csv-map (map(*)) Map with CSV contents
: @return An XML fragment containing collection metadata.
:)
declare function local:getCollectionMetadata($dbName as xs:string, $collection as xs:string, $csv-map as map(*)? := ()) {
  let $metadataMap :=  db:get($dbName, $G:metadata)//metadataMap
  return
    if ($metadataMap)
    then
      let $metadatas := 
        let $csv-map := $csv-map otherwise local:getCSV-map($dbName, "collection")
        for $metadata in $metadataMap//mapping/node()[@scope = "collection"]
        let $source := functx:substring-after-last($metadata/@source, "/")
        let $findIdInCSV := normalize-space($metadata/@resourceId)
        let $csv := $csv-map($source)
        let $record := $csv/*:record[node()[name() = $findIdInCSV][. = $collection]]       
        return
          if ($metadata/@resourceId = "all")
          then 
            let $key := $metadata/name()
            return element {$key} { concat($metadata/@prefix, $metadata, $metadata/@suffix) }
          else
            if ($record and $metadata) 
            then local:createContent($metadata, $record)
            else ()
      return
        if ($metadatas/name() = "dc:title")
        then $metadatas
        else  (
          <dc:title>{$collection}</dc:title>,
          $metadatas
        )
    else <dc:title>{$collection}</dc:title>
};

(:~  
 : Returns a map with all CSV contents from the specified database for which source paths exist.
 : @param $dbName (xs:string) The name of the XML database.
 : @return map
 :)
declare function local:getCSV-map(
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
declare function local:createContent(
  $itemDeclaration,
  $csv-record as map(*)
) {
  let $key := $itemDeclaration/name()
  let $element := $itemDeclaration/@value
  let $value := (
    for $v in $csv-record($element)
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

(: let $x := local:getCSV-map("theater", "collection")
return $x :)

local:createResourcesRegister($dbName, $idProject)

(: local:createResourcesRegister($dbName, $idProject) => prof:track(), :)
(: local:collections($dbName, $idProject) :)
(: local:document($dbName, $idProject) => prof:track() :)

(: local:collections($dbName, $idProject) => prof:time() :)

(: Check this function on all documents (more than 3000) :)
(: for $doc in db:get($dbName)/*:TEI
let $id := $doc/@xml:id
return
  local:getDocumentMetadata($dbName, $doc, $id) => prof:time() :)

(: Check the same function only on one document :)
(: local:getDocumentMetadata($dbName, db:get($dbName)/*:TEI[@xml:id="ENCPOS_1972_18"], "ENCPOS_1972_18") => prof:time() :)
