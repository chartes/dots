xquery version "4.0";

(:~
: Module to delete DoTS project registers from a specified database.
: This module allows a DoTS user to:
: - remove the project entry from the central "dots" database (dots_db_switcher.xml),
: - optionally delete the entire project database, or just its DoTS registers 
:   ("resources.xml" and "fragments.xml").
: Author: École nationale des chartes  
: Since: 2023-10-12  
: Version: 1.0
:)
module namespace dots.delete = "backend/dots_registers_delete";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

(:~
: Deletes DoTS registers for a given project.
: @param  $dbName Name of the project database.
: @param  $option If "true", the entire database is dropped.
:                 If not, only the registers ("resources.xml" and "fragments.xml") are deleted.
: @return Performs update operations in the "dots" database and optionally removes the project database.
:)
declare updating function dots.delete:handle($dbName as xs:string, $option as xs:string) {
  dots.delete:dbSwitch($dbName),
  dots.delete:registers($dbName, $option)
};

(:~
: Updates the database "dots" by:
: - updating the modification timestamp,
: - decrementing the total number of projects,
: - removing the <member> entry corresponding to the given database name.
: @param  $dbName name of the project database to remove from the registry.
: @return updates the <dbSwitch> document in the "dots" database.
:)
declare %private updating function dots.delete:dbSwitch($dbName as xs:string) {
  let $dbDots := db:get($G:dots)/dbSwitch
  let $totalProjects := $dbDots//totalProjects
  let $modified := $dbDots//dct:modified
  let $member := $dbDots//member
  return (
    replace value of node $modified with current-dateTime(),
    replace value of node $totalProjects with count($dbDots//project) - 1,
    delete nodes $member/*[@dbName = $dbName]
  )
};

(:~
: Deletes the DoTS registers or the entire database depending on the option.
: @param  $dbName name of the database to operate on.
: @param  $option if "true", deletes the full database. Otherwise, only the registers are deleted.
: @return executes deletion operations accordingly.
:)
declare %private updating function dots.delete:registers($dbName as xs:string, $option as xs:string) {
  if ($option = "true") then (
    db:drop($dbName)
  ) else (
      db:delete($dbName, $G:resourcesRegister),
      db:delete($dbName, $G:fragmentsRegister)  
  )
};
