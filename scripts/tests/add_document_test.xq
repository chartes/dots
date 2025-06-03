xquery version "4.0";

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";
import module namespace utils = "resolver/utils";
import module namespace fragments = "backend/fragments_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare variable $docId external;
declare variable $project_dir_path external;
declare variable $dbName := utils_dots:getDbName($docId);
declare variable $document := utils_dots:findPathDoc($dbName, $docId);

(:~~~~~~~~~
: Unit Tests 
~~~~~~~~~~:)
(:  
: Ce test permet de s'assurer que le nombre de fichiers TEI dans la base BaseX ET le nombre de document (c'est-à-dire le nombre d'élément <document/>) dans le registre des ressources DoTS du projet sont concordants.
:)
declare %unit:test function local:checkDocumentNumber() {
  let $countTEIFile := count(db:get($dbName)/tei:TEI)
  let $countDocInRegister := count(db:get($dbName, $G:resourcesRegister)//dots:document)
  return
    unit:assert-equals($countTEIFile, $countDocInRegister)
};

(:  
: This test ensures that the document is properly present in the BaseX database
:)
declare %unit:test function local:checkDocInDb() {
  unit:assert($document)
};

(:  
: This test ensures that the document's access path in the BaseX database matches the document's path in the repository folder.
: This test is important because the path reflects the document's belonging to a collection, sub-collection, etc..
:)
declare %unit:test function local:checkPaths() {
  let $pathDocInDb := utils_dots:findPath($dbName, $docId)
  let $pathDocInFolder := substring-after(utils_dots:getPathInFolder($docId, $project_dir_path), "data/")
  return
    unit:assert-equals($pathDocInDb, $pathDocInFolder)
};

(:  
: This test verifies that the document is registered in the project's DoTS resource registry.
: It also compares the value of the @maxCiteDepth attribute with the depth level of the <citeStructure/> elements in the TEI file. Both values must be identical.
: Finally, it verifies that each parent collection exists in the resources register and that, for each parent collection of the document, the number of documents within these collections matches the value displayed in the @totalChildren attribute.
:)
declare %unit:test function local:checkDocInRegister() {
  let $docEntry := db:get($dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $docId]
  let $maxCiteDepth := fragments:getMaxCiteDepth($document//tei:refsDecl, 0)
  return
    (
      unit:assert($docEntry/dc:title),
      unit:assert-equals(xs:integer($docEntry/@maxCiteDepth), xs:integer($maxCiteDepth)),
      for $collectionId in tokenize($docEntry/@parentIds, " ")
      let $collection := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $collectionId]
      let $totalChildren := $collection/@totalChildren
      let $countChildren := count(db:get($dbName, $G:resourcesRegister)//node()[contains(@parentIds, $collectionId)])
      return
        (
          unit:assert($collection, concat("La collection '", $collectionId,  "' n'existe pas.")),
          unit:assert-equals(xs:integer($totalChildren), $countChildren)
        )
    )
};

(
  local:checkDocumentNumber(),
  local:checkDocInDb(),
  local:checkPaths(),
  local:checkDocInRegister()
)

