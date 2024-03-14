xquery version '3.0' ;

module namespace deployTest = "https://github.com/chartes/dots/deploimentTests";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace functx = 'http://www.functx.com';

declare default element namespace "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $deployTest:dbSwitchModel := doc(concat($G:webapp, "dots/tests/data_model/dots_db/dots_db_switcher.xml"));

declare variable $deployTest:mappingModel := doc(concat($G:webapp, "dots/tests/data_model/dots_db/dots_default_metadata_mapping.xml"));

(: Tests de dots_db_init :)
declare function deployTest:testDbSwitch() {
  let $dots := db:get($G:dots)/dbSwitch
  let $totalProjects := $dots/metadata/totalProjects
  let $member := $dots/member
  return
    (
      deep-equal($totalProjects, $deployTest:dbSwitchModel/dbSwitch/metadata/totalProjects),
      deep-equal($member, $deployTest:dbSwitchModel/dbSwitch/member)
    )
};

declare function deployTest:testMetadataMapping() {
  let $dots := db:get($G:dots)
  let $mapping := $dots/metadataMap/mapping
  let $mappingModel := $deployTest:mappingModel/metadataMap/mapping
  return
    (
      deep-equal($mapping, $mappingModel)
    )
};

declare %unit:test function deployTest:check-boolean-response($returned) {
  let $expected := true()
  for $r in $returned
  return
    unit:assert-equals($r, $expected) 
};


(: Tests de project_db_init :)
declare function deployTest:getNumberResources() {
  let $collections :=
    for $collection in db:dir("encpos", "")
    where $collection != "metadata"
    return
      $collection
  let $documents := count(db:get("encpos")/tei:TEI)
  return
    (
      count($collections),
      $documents
    )
};

declare %unit:test function deployTest:checkTotalResources($returned) {
  let $collectionsExpected := 4
  let $documentsExpected := 9
  return
    (
      unit:assert-equals($returned[1], $collectionsExpected),
      unit:assert-equals($returned[2], $documentsExpected)
    ) 
};









