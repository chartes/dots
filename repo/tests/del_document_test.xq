xquery version "4.0";


import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare variable $dbName external;
declare variable $resourceId external;

(:~~~~~~~~~
: Unit Tests 
~~~~~~~~~~:)

declare %unit:test function local:checkNoDoc() {
  let $docAvailable := db:get($dbName)/tei:TEI[@xml:id = $resourceId] or db:get($dbName)/node()[ends-with(db:path(.), $resourceId)]
  return 
    unit:assert(not($docAvailable), concat("Le document TEI ", $resourceId, " est toujours présent dans la db ", $dbName, "."))
};

declare %unit:test function local:checkNoDocInRegister() {
  let $docInReg := db:get($dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $resourceId]
  return
    unit:assert(not($docInReg), concat("Le document ", $resourceId, " est toujours mentionné dans le registre des ressources DoTS de la db ", $dbName, "."))
};

declare %unit:test function local:checkNoFragInRegister() {
  let $fragInReg := db:get($dbName, $G:fragmentsRegister)//dots:fragment[@resourceId = $resourceId]
  return
    unit:assert(not($fragInReg), concat("Les fragments du document TEI ", $resourceId, " sont toujours présents dans le registre des fragments DoTS de la db ", $dbName))
};

declare %unit:test function local:checkTotalChildren() {
  let $resourcesRegister := db:get($dbName, $G:resourcesRegister)
  return
    for $coll in $resourcesRegister//dots:collection
    let $id := $coll/@dtsResourceId
    let $totalChildren := xs:integer($coll/@totalChildren)
    let $count := count($resourcesRegister//node()[tokenize(@parentIds) = $id])
    return
      unit:assert-equals($totalChildren, $count, concat("La valeur de @totalChildren (", $totalChildren, ") de la collection ", $id, " ne coïncide pas avec le nombre de documents (", $count, ") appartenant à cette collection "))
};

local:checkTotalChildren()



