xquery version "4.0";

(:~  
: This module contains unit tests to verify the correct creation of the DoTS registers (resources and fragments registers).
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-04
: @version  1.0
:)

import module namespace G = 'globals';
import module namespace resources = "backend/resources_register_builder";

import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace dots_error = "error/dots_error"; 

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dots = "https://github.com/chartes/dots/";

declare function local:downloadDefaultData() {
  let $url := "https://github.com/chartes/dots_documentation/archive/refs/heads/dev.zip"
  let $zip := fetch:binary($url)
  let $entries  := archive:entries($zip)
  let $contents := archive:extract-binary($zip)
  return 
    for-each-pair($entries, $contents, fn($entry, $content) {
      file:create-dir(replace($entry, "[^/]+$", "")),
      file:write-binary($entry, $content)
    })
};

declare variable $defaultProjectDirPath := concat(file:current-dir(), "dots_documentation-dev/data_test/periodiques/encpos_by_abstract");

declare variable $dbName external := "test";
declare variable $projectDirPath external := (local:downloadDefaultData(), $defaultProjectDirPath);
declare variable $topCollectionId external := "test";
declare variable $options external := false();

(:~
: This function is executed before the test suite. It creates the BaseX database tailored to the needs of DoTS for testing.
: @return The database is created in BaseX.
:)
declare %updating %unit:before-module function local:createProjectTest() {
  if (db:exists($dbName)) then () else dots.create:db($dbName, $projectDirPath)
};

(:~
: This function runs before the test suite and creates the necessary registers for DoTS.
: @return resources_register.xml and fragments_register.xml are created.
:)
declare %updating %unit:before-module function local:createRegisters() {
  if (db:get($dbName, $G:resourcesRegister)) 
  then () 
  else resources:createResourcesRegister($dbName, $topCollectionId)
};

(:~
 : This test function validates all TEI documents in the database against the RNG schemas for both resources and fragments registers.
 : @return Success if each TEI document is valid according to the expected schemas.
:)
declare %unit:test function local:validateRng() {
  for $TEI in db:get($dbName)/tei:TEI
  return
    (
      unit:assert(validate:rng-report($TEI, $G:resourcesValidation)),
      unit:assert(validate:rng-report($TEI, $G:fragmentsValidation))
    )
};

(:~
 : This test checks that there is exactly one top-level project (i.e., a collection with no parentIds) in the resources register.
 : @return Success if only one root collection exists.
:)
declare %unit:test function local:assertProjectIsUnique() {
  let $countProject := count(db:get($dbName, $G:resourcesRegister)//dots:collection[not(@parentIds)])
  return
    unit:assert-equals($countProject, 1)
};

(:~
 : This test verifies that each attribute @dtsResourceId in the resources register is unique.
 : @return Success if no duplicate identifiers are found.
:)
declare %unit:test function local:assertUniqueResourcesIdentifiers() {
  let $dtsResourceId := db:get($dbName, $G:resourcesRegister)//dots:member/node()/@dtsResourceId
  return
    unit:assert(empty(duplicate-values($dtsResourceId)))
};

(:~
 : This test verifies that each attribute @ref in the fragments register is unique.
 : @return Success if all fragment references are distinct.
:)
declare %unit:test function local:assertUniqueFragmentsIdentifiers() {
  let $ref := db:get($dbName, $G:fragmentsRegister)//dots:member/dots:fragment/@ref
  return
    unit:assert(empty(duplicate-values($ref)))
};

(:~
 : This test verifies that the value of @totalChildren for each collection matches the number of members referring to it as a parent.
 : @return Success if the declared number of children equals the actual count.
:)
declare %unit:test function local:assertCorrectTotalChildren() {
  for $collection in db:get($dbName, $G:resourcesRegister)//dots:collection
  let $idCollection := $collection/@dtsResourceId
  let $n := xs:integer($collection/@totalChildren)
  let $countMembersCollection := count(db:get($dbName, $G:resourcesRegister)//dots:member/node()[tokenize(@parentIds) = $idCollection])
  return
    unit:assert-equals($n, $countMembersCollection)
};

(:~
: This function is executed after the test suite. It deletes the BaseX database created for testing.
: @return The database is removed from the system.
:)
declare %updating %unit:after-module function local:deleteProjectTest() {
  if ($options = true()) 
  then 
    dots.delete:handle($dbName, "true")
}; 

declare %unit:after-module function local:deleteDefaultDataFile() {
  let $defaultDataFile := concat(file:current-dir(), "dots_documentation-dev")
  where file:exists($defaultDataFile)
  return
    file:delete($defaultDataFile, true())
};

()
