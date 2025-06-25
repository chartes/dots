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

declare variable $dbName external := "test";

(:~
: This function adds missing `xml:id` attributes to TEI fragments before running module tests.
: @return Updates fragments in the database by assigning `xml:id` attributes when they are missing.
:)
(: declare %updating %unit:before-module function local:addTeiIds() {
  let $nodeIdToTest := db:get($dbName, $G:fragmentsRegister)//fragment[matches(@ref, "r[0-9]*")][1]/@node-id
  where not(db:get-id($dbName, $nodeIdToTest)/@xml:id)
  return
    dots.update:addXmlIdToFragment($dbName)
}; :)

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

()