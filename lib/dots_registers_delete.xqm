xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS de supprimer les registres DoTS du projet de son choix
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-12
: @version  1.0
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

declare updating function dots.lib:handleDelete($dbName as xs:string) {
  dots.lib:dbSwitchDelete($dbName),
  dots.lib:registersDelete($dbName)
};

declare updating function dots.lib:dbSwitchDelete($dbName as xs:string) {
  let $dbDots := db:get($G:dots)/dbSwitch
  let $totalProjects := $dbDots//totalProjects
  let $modified := $dbDots//dct:modified
  let $member := $dbDots//member
  return
    (
      replace value of node $modified with current-dateTime(),
      replace value of node $totalProjects with xs:integer($totalProjects) - 1,
      for $member in $member/node()[@dbName = $dbName]
      return
        delete node $member
    )
};

declare updating function dots.lib:registersDelete($dots.lib:dbName as xs:string) {
  db:delete($dots.lib:dbName, $G:resourcesRegister),
  db:delete($dots.lib:dbName, $G:fragmentsRegister)
  
};