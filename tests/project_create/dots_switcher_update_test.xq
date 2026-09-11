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

declare default element namespace "https://github.com/dots-suite/dots";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $dbName external := "test";

(:~
: This function ensures the project is registered in the DTS switcher before running module tests.
: @return Adds an entry for each resource of the project in the switcher DoTS database if the project is not already registered.
:)
(: declare %updating %unit:before-module function local:updateSwitcher() {
  if (db:get($G:dots, $G:dbSwitcher)//project[@dtsResourceId=$topCollectionId])
  then ()
  else dots.update:switcher($dbName)
}; :)

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
  let $validateSwitcher := validate:rng($switcher, $G:dbSwitchValidation)
  return
    unit:assert-equals($validateSwitcher, (), $validateSwitcher)
};

(:~
 : This test verifies that each project database exists.
 : @return An assertion that the db project exists.
:)
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

() 
