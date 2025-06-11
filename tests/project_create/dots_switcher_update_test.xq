xquery version "4.0";

(:~  
: This module contains unit tests to verify the validity of a DoTS BaseX database. 
: It checks that the project switcher resource conforms to its Relax NG schema,
: that the total number of declared projects matches the number of actual project elements,
: that each project databalse exists,
: and that each attribute @dtsResourceId is unique.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-10
: @version  1.0
:)

import module namespace G = 'globals';
import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace dots_error = "error/dots_error"; 
import module namespace resources = "backend/resources_register_builder";
import module namespace dots.addTeiId = "backend/TEI_add_id";
import module namespace dots.update = "backend/dots_switcher_update";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $dbName external := "test";
declare variable $topCollectionId external := "test";
declare variable $projectDirPath external := (local:downloadDefaultData(), $defaultProjectDirPath);
declare variable $options external := false();

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

declare %updating %unit:before-module function local:addTeiIds() {
  let $nodeIdToTest := db:get($dbName, $G:fragmentsRegister)//fragment[matches(@ref, "r[0-9]*")][1]/@node-id
  where not(db:get-id($dbName, $nodeIdToTest)/@xml:id)
  return
    dots.addTeiId:addXmlIdToFragment($dbName)
};

declare %updating %unit:before-module function local:updateSwitcher() {
  if (db:get($G:dots, $G:dbSwitcher)//project[@dtsResourceId=$topCollectionId])
  then ()
  else dots.update:switcher($dbName)
};

(:~
: This test verifies that the declared total number of projects in the DoTS metadata 
: matches the actual number of <project> elements present in the database.
: @return An assertion that the count of <project> elements equals the declared total.
:)
declare %unit:test function local:checkTotalProject() {
  let $totalProjects := xs:integer(db:get($G:dots)//totalProjects)
  let $countProject := count(db:get($G:dots, $G:dbSwitcher)//project)
  return
    unit:assert-equals($totalProjects, $countProject)
};

(:~
 : This test verifies that the DoTS database switcher file conforms to its Relax NG schema.
 : @return An assertion that the resource passes RNG validation.
:)
declare %unit:test function local:validateRng() {
  let $switcher := db:get($G:dots, $G:dbSwitcher)
  return
    unit:assert(validate:rng-report($switcher, $G:dbSwitchValidation))
};

declare %unit:test function local:checkDbExists() {
  for $project in db:get($G:dots)//member/project/@dbName
  return
    unit:assert(db:exists($project), dots_error:dbError($dbName))
};

(:~
 : This test verifies that each attribute @dtsResourceId in the resources register is unique.
 : @return Success if no duplicate identifiers are found.
:)
declare %unit:test function local:assertUniqueIdentifiers() {
  let $dtsResourceId := db:get($G:dots, $G:dbSwitcher)//member/node()/@dtsResourceId
  return
    unit:assert(empty(duplicate-values($dtsResourceId)))
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
