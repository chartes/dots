xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de supprimer les registres DoTS du projet de son choix
: @author École nationale des chartes
: @since 2023-10-12
: @version  1.0
:)
module namespace dots.delete = "backend/dots_registers_delete";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

declare updating function dots.delete:handle($dbName as xs:string, $option as xs:string) {
  dots.delete:dbSwitch($dbName),
  dots.delete:registers($dbName, $option)
};

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

declare %private updating function dots.delete:registers($dbName as xs:string, $option as xs:string) {
  if ($option = "true") then (
    db:drop($dbName)
  ) else (
      db:delete($dbName, $G:resourcesRegister),
      db:delete($dbName, $G:fragmentsRegister)  
  )
};
