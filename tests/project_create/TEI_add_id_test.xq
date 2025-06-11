xquery version "4.0";

(:~  
: This module contains unit tests to check that all fragments in the DoTS fragment register 
: with a reference of the form "r[0-9]*" are correctly associated with a target node 
: that has an @xml:id attribute.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-10
: @version  1.0
:)

import module namespace G = 'globals';
import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace dots_error = "error/dots_error"; 
import module namespace resources = "backend/resources_register_builder";
import module namespace dots.update = "backend/TEI_add_id";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: Downloads the default test data if no `$projectDirPath` is provided by the user.
: @return The default test data is downloaded and extracted into the current directory.
:)
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
declare variable $topCollectionId external := "test";
declare variable $projectDirPath external := "(local:downloadDefaultData(), $defaultProjectDirPath)";
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
: This function adds missing `xml:id` attributes to TEI fragments before running module tests.
: @return Updates fragments in the database by assigning `xml:id` attributes when they are missing.
:)
declare %updating %unit:before-module function local:addTeiIds() {
  let $nodeIdToTest := db:get($dbName, $G:fragmentsRegister)//fragment[matches(@ref, "r[0-9]*")][1]/@node-id
  where not(db:get-id($dbName, $nodeIdToTest)/@xml:id)
  return
    dots.update:addXmlIdToFragment($dbName)
};

(:~
: This test verifies that all <fragment> elements with a @ref matching "r[0-9]*" 
: are correctly linked to an existing node in the database via their @node-id.
: @return An assertion that each referenced node exists and has an @xml:id attribute.
:)
declare %unit:test function local:checkIdsCreated() {
  for $fragment in db:get($dbName, $G:fragmentsRegister)//fragment
  let $ref := $fragment/@ref
  where matches($ref, "r[0-9]*")
  let $node-id := $fragment/@node-id
  return
    unit:assert(db:get-id($dbName, $node-id)/@xml:id)
};

(:~
: This function is executed after the test suite. It deletes the BaseX database created for testing.
: @return The database is removed from the system.
:)
declare %updating %unit:after function local:deleteProjectTest() {
  if ($options = true()) 
  then 
    dots.delete:handle($dbName, "true")
}; 

(:~
: This function deletes the default test data if it exists.
: @return The default test data directory is removed from the current directory.
:)
declare %unit:after function local:deleteDefaultDataFile() {
  let $defaultDataFile := concat(file:current-dir(), "dots_documentation-dev")
  where file:exists($defaultDataFile)
  return
    file:delete($defaultDataFile, true())
};

()