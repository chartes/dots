xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS d'ajouter un ou plusieurs documents au "resources register" d'une db
: @author École nationale des chartes
: @since 2024-10-16
: @version  1.0
:)
(: module namespace dots.add_doc_to_registers = "backend/project_add_document_to_registers"; :)

import module namespace G = "globals";
import module namespace fragments = "backend/fragments_register_builder";
import module namespace resources = "backend/resources_register_builder";
import module namespace functx = 'http://www.functx.com';

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";


declare function local:addToReg($dbName as xs:string, $topCollectionId as xs:string, $path, $csvPath as xs:string, $separator as xs:string) {
  if ($csvPath)
  then local:addToRegFromCSV($dbName, $topCollectionId, $path, $csvPath, $separator)
  else local:addToRegFromDoc($dbName, $topCollectionId, $path, $separator)
    
};

declare function local:addToRegFromCSV($dbName as xs:string, $topCollectionId as xs:string, $path, $csvPath, $separator as xs:string) {
  let $csv := csv:doc($csvPath, map {
    "header": true(),
    "separator": $G:separator
  })
  for $doc in collection($path)
  let $id := 
    if ($doc/tei:TEI/@xml:id) 
    then $doc/tei:TEI/@xml:id
    else functx:substring-after-last(base-uri($doc), "/")
  let $record := $csv/*:csv/*:record[*:documentId = $id]
  let $maxCiteDepth := fragments:getMaxCiteDepth($doc//tei:refsDecl, 0)
  let $collection := 
    for $coll in tokenize($record/*:collectionsId, $separator)
    (: where db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId = $coll] :)
    return
      <collection>{normalize-space($coll)}</collection>
  order by $id
  let $metadata := resources:getDocumentMetadata($dbName, $doc, $id)
  return
    <document dtsResourceId="{$id}" maxCiteDepth="{$maxCiteDepth}" parentIds="{if ($collection) then $collection else $topCollectionId}">{
      $metadata
    }</document>
};

declare function local:addToRegFromDoc($dbName as xs:string, $topCollectionId as xs:string, $path, $separator as xs:string) {
  for $doc in collection($path)
  let $id := 
    if ($doc/tei:TEI/@xml:id) 
    then $doc/tei:TEI/@xml:id
    else functx:substring-after-last(base-uri($doc), "/")
  let $maxCiteDepth := fragments:getMaxCiteDepth($doc//tei:refsDecl, 0)
  let $title := normalize-space($doc/tei:TEI//tei:titleStmt/tei:title[@type = "main" or position() = 1])
  let $author := normalize-space($doc/tei:TEI//tei:titleStmt/tei:author)
  let $publisher := normalize-space($doc/tei:TEI//tei:publicationStmt/tei:publisher)
  return
    <document dtsResourceId="{$id}" maxCiteDepth="{$maxCiteDepth}" parentIds="{$topCollectionId}">{
      <dc:title>{$title}</dc:title>,
      if ($author) then <dc:creator>{$author}</dc:creator>,
      if ($publisher) then <dct:publisher>{$publisher}</dct:publisher>
    }</document>
};


(:  
let $dtsResourceId := 
    if ($document/@xml:id)
    then $document/@xml:id
    else
      if (contains($path, "/"))
      then functx:substring-after-last($path, "/")
      else $path
:)


(: local:addToReg("encpos", "ENCPOS", "/home/ppons/Bureau/dots_encpos/dots_encpos_2024/encpos_data_2024/data/ENCPOS_2024", "", "\|") :)
local:addToRegFromCSV("encpos", "ENCPOS", "/home/ppons/Bureau/dots_encpos/dots_encpos_2024/encpos_data_2024/data/ENCPOS_2024", "/home/ppons/Bureau/dots_encpos/dots_encpos_2024/add_doc.csv", "\|")

