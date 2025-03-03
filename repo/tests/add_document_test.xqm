xquery version "4.0";

module namespace test_add = "tests/add_document_test";

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";
import module namespace utils = "resolver/utils";
import module namespace fragments = "backend/fragments_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare variable $test_add:docId external;
declare variable $test_add:project_dir_path external;
declare variable $test_add:dbName := utils_dots:findDbName($test_add:docId);
declare variable $test_add:document := utils:getDocument($test_add:dbName, $test_add:docId);

(:~~~~~~~~~
: Unit Tests 
~~~~~~~~~~:)

declare %unit:test function test_add:checkDocumentNumber() {
  let $countTEIFile := count(db:get($test_add:dbName)/tei:TEI)
  let $countDocInRegister := count(db:get($test_add:dbName, $G:resourcesRegister)//dots:document)
  return
    unit:assert-equals($countTEIFile, $countDocInRegister)
};

declare %unit:test function test_add:checkDocInDb() {
  unit:assert($test_add:document)
};

declare %unit:test function test_add:checkPaths() {
  let $pathDocInDb := utils_dots:findPathDoc($test_add:dbName, $test_add:docId)
  let $pathDocInFolder := substring-after(utils_dots:getPathInFolder($test_add:docId, $test_add:project_dir_path), "data/")
  return
    unit:assert-equals($pathDocInDb, $pathDocInFolder)
};

declare %unit:test function test_add:checkDocInRegister() {
  let $docEntry := db:get($test_add:dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $test_add:docId]
  let $maxCiteDepth := fragments:getMaxCiteDepth($test_add:document//tei:refsDecl, 0)
  return
    (
      unit:assert($docEntry/dc:title),
      unit:assert-equals(xs:integer($docEntry/@maxCiteDepth), xs:integer($maxCiteDepth)),
      for $collectionId in tokenize($docEntry/@parentIds, " ")
      let $collection := db:get($test_add:dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $collectionId]
      let $totalChildren := $collection/@totalChildren
      let $countChildren := count(db:get($test_add:dbName, $G:resourcesRegister)//node()[contains(@parentIds, $collectionId)])
      return
        (
          unit:assert($collection),
          unit:assert-equals(xs:integer($totalChildren), $countChildren)
        )
    )
};



