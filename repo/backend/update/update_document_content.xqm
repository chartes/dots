xquery version "4.0";

(:~  
: This module allows updating the content of a document.
: @author École nationale des chartes - Philippe Pons
: @since 2025-01-16
: @version  1.0
:)

module namespace update_doc_ctt = "backend/update/update_document_content"; 

import module namespace G = "globals";
import module namespace dots_error = "error/dots_error";
import module namespace utils = "resolver/utils";
import module namespace utils_dots = "utils_dots";
import module namespace resources = "backend/resources_register_builder";
import module namespace fragments = "backend/fragments_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~  This function allows finding the document $docId in his db
: @param document identifier
: @return TEI document
:)
declare function update_doc_ctt:findDocInDb($docId) {
  let $db := utils_dots:getDbName($docId)
  return
    utils_dots:findPathDoc($db, $docId)
};

(:~  This function allows checking if the document $docId in the db has DoTS identifiers
@param $docId document identifier
@return boolean
:)
declare function update_doc_ctt:CheckDotsId($doc) {
  some $ids in  $doc//node()/@xml:id
  satisfies matches($ids, "r[0-9]+")
};

declare function update_doc_ctt:CheckPath($pathDoc1 as xs:string, $pathDoc2 as xs:string) {
  let $comparison := if ($pathDoc1 = $pathDoc2) then true() else false()
  return
    try {
      dots_error:pathError($comparison)
    } catch update_doc_ctt:path {
      'Error: ' || $err:description
    }
};

(:~ This function compare two documents 
: @param $doc1 first document to compare
: @param $doc2 second document to compare
: @return boolean
:)
declare function update_doc_ctt:compareDocs($doc1, $doc2) {
  deep-equal(
    $doc1,
    $doc2,
    { 'items-equal': fn($a, $b) {
    if($a instance of text()) then (
      $b instance of text()
    )
  }}
  )
};

(:~ This function allows updating a document 
: @param $docId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return replace the document $docId in a basex db with document $docId in the folder $project_dir_path
:)
declare updating function update_doc_ctt:handleUpdate($docId as xs:string, $project_dir_path) {
  let $docPath := utils_dots:getPathInFolder($docId, $project_dir_path)
  let $docInFolder :=  utils_dots:findDocInFolder(concat($project_dir_path, utils_dots:getPathInFolder($docId, $project_dir_path)))
  let $docInDb := update_doc_ctt:findDocInDb($docId)
  let $dbPath := db:path($docInDb)
  let $checkPath := update_doc_ctt:CheckPath($docPath, $dbPath)
  let $checkDotsIdInDocInFolder := update_doc_ctt:CheckDotsId($docInFolder)
  let $checkDotsIdInDocInDb := update_doc_ctt:CheckDotsId($docInDb)
  return
    if ($checkDotsIdInDocInDb and not($checkDotsIdInDocInFolder))
    then 
      (
        update:output("Les identifiants DoTS sont absents de votre document."),
        db:put(db:name($docInDb), concat($project_dir_path, $docPath), $docPath)
      )
    else  
      if ($checkPath)
      then update:output($checkPath)
      else 
        db:put(db:name($docInDb), concat($project_dir_path, $docPath), $docPath) 
};

(:~ This function allows updating the dots registers (dots/resources_register.xml and dots/fragments_register.xml)
: @param $docId document identifier
: @return replace fragments[@dtsResourceId=$docId] into dots/fragments_register.xml ; replace the attribute @maxCiteDepth in dots/resources_register.xml
:)
declare updating function update_doc_ctt:updateRegisters($docId, $project_dir_path) {
  let $dbName := utils_dots:getDbName($docId)
  let $csv := resources:getCSV-map($dbName, "fragment")
  let $docInDb := update_doc_ctt:findDocInDb($docId)/tei:TEI
  let $docInFolder := utils_dots:findDocInFolder(concat($project_dir_path, utils_dots:getPathInFolder($docId, $project_dir_path)))
  let $compareDoc := update_doc_ctt:compareDocs($docInFolder, $docInDb)
  return
    if ($compareDoc)
    then ()
    else
      let $maxCiteDepth := fragments:getMaxCiteDepth($docInDb//tei:refsDecl, 0)
      let $fragments := db:get($dbName, $G:fragmentsRegister)//dots:fragment[@resourceId = $docId]
      let $docRegister := db:get($dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $docId]
      for $citeStructurePosition in $docInDb//tei:refsDecl/tei:citeStructure
      return 
        (
          delete nodes $fragments,
          insert nodes fragments:handleCiteStructure($dbName, $docInDb, "", $citeStructurePosition, 1, $docId, "", "", $maxCiteDepth, $csv) after db:get($dbName, $G:fragmentsRegister)//dots:fragment[@resourceId = $docId][1],
          replace value of node $docRegister/@maxCiteDepth with $maxCiteDepth
        )
};
  


