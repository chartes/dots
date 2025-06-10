xquery version "4.0";

(:~  
: This module contains unit tests to verify the correct initialization of a DoTS BaseX database from a project directory.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-10
: @version  1.0
:)

import module namespace G = 'globals';
import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace dots_error = "error/dots_error"; 

declare default element namespace "https://github.com/chartes/dots/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $dbName external := "comptes";
declare variable $projectDirPath external := "";
declare variable $options external := false();

(:~
: This function is executed before the test suite. It creates the BaseX database tailored to the needs of DoTS for testing.
: @return The database is created in BaseX.
:)
declare %updating %unit:before function local:createProjectTest() {
  if (db:exists($dbName)) then () else dots.create:db($dbName, $projectDirPath)
};

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
declare %updating %unit:after-module function local:deleteProjectTest() {
  if ($options = true()) then dots.delete:handle($dbName, "true")
}; 

()