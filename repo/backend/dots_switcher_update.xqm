xquery version "4.0";

(:~
: This module provides update functions for the DoTS switcher,
: a central registry that lists all available projects and resources,
: and indicates the database to which each project or resource belongs.
: Author: École nationale des chartes  
: Since: 2025-07-02  
: Version: 1.0
:)
 
module namespace dots.update = "backend/dots_switcher_update"; 

import module namespace G = "globals";

declare default element namespace "https://github.com/dots-suite/dots";
declare namespace dct = "http://purl.org/dc/terms/";

(:~
: This function updates the DoTS switcher by registering a new project and its members.
: This function updates the modification date and the total number of projects.
: It also adds a `<project>` element for the main project and appends
: any member resources (collections or documents) with their identifiers.
: @param $dbName  the name of the database containing the new project's data.
: @return a sequence of update expressions: updating the date, the total project count, and inserting new elements.
:)
declare updating function dots.update:switcher($dbName as xs:string, $cacheOption as xs:boolean := false() ) {
  let $switcher := db:get($G:dots, $G:dbSwitcher)/dbSwitch
  let $dateModified := $switcher/metadata/dct:modified
  let $totalProject := $switcher/metadata/totalProjects
  let $members := (
    dots.update:project($dbName, $cacheOption),
    dots.update:members($dbName)
  )
  return (
    replace value of node $dateModified with current-dateTime(),
    replace value of node $totalProject with $totalProject + 1,
    insert nodes $members as last into $switcher/member
  )
};

(:~
: This function builds the `<project>` element for a new project if not already registered in the switcher.
: @param $dbName  the name of the project's database to register.
: @return         a `<project>` element, or an empty sequence if the project is already registered.
:)
declare %private function dots.update:project($dbName as xs:string, $cacheOption as xs:boolean := false()) {
  let $dtsResourceId := db:get($dbName, $G:resourcesRegister)//member/collection[not(@parentIds)]/@dtsResourceId
  let $projectInSwitcher := db:get($G:dots)//member/project[@dbName = $dbName]
  where not($projectInSwitcher)
  return <project dtsResourceId="{ $dtsResourceId }" dbName="{$dbName}" cacheOption="{$cacheOption}"/>
};

(:~
: This function builds elements for the project's member resources (e.g., documents or collections) with the necessary attributes.
: @param $dbName  The name of the project's database.
: @return         A sequence of XML elements representing the resources to be added.
 :)
declare %private function dots.update:members($dbName as xs:string) {
  for $resources in db:get($dbName, $G:resourcesRegister)//member/node()[@parentIds]
  let $type := $resources/name()
  let $dtsResourceId := $resources/@dtsResourceId
  let $resourceInSwitcher := db:get($G:dots)//member/node()[@dtsResourceId = $dtsResourceId][@dbName = $dbName]
  where not($resourceInSwitcher)
  return element { $type } {
    attribute { "dtsResourceId" } { $dtsResourceId },
    attribute { "dbName" } { $dbName }
  }
};
