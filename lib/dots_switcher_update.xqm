xquery version "3.1";

module namespace dots.lib = "https://github.com/chartes/dots/lib"; 

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

declare updating function dots.lib:switcher_update($dbName) {
  let $switcher := db:get($G:dots, $G:dbSwitcher)/dbSwitch
  let $dateModified := $switcher/metadata/dct:modified
  let $totalProject := $switcher/metadata/totalProjects
  let $members :=
    (
      dots.lib:getProject($dbName),
      dots.lib:getMembers($dbName)
    )
  return
    (
      replace value of node $dateModified with current-dateTime(),
      replace value of node $totalProject with $totalProject + 1,
      insert nodes $members as last into $switcher/member
    )
};

declare function dots.lib:getProject($dbName as xs:string) {
  let $dtsResourceId := db:get($dbName, $G:resourcesRegister)//member/collection[not(@parentIds)]/@dtsResourceId
  let $projectInSwitcher := db:get($G:dots)//member/project[@dbName = $dbName]
  return
    if ($projectInSwitcher)
    then ()
    else 
      <project dtsResourceId="{$dtsResourceId}" dbName="{$dbName}"/>
};

declare function dots.lib:getMembers($dbName as xs:string) {
  for $resources in db:get($dbName, $G:resourcesRegister)//member/node()[@parentIds]
  let $type := $resources/name()
  let $dtsResourceId := $resources/@dtsResourceId
  let $resourceInSwitcher := db:get($G:dots)//member/node()[@dtsResourceId = $dtsResourceId][@dbName = $dbName]
  return
    if ($resourceInSwitcher)
    then ()
    else
      element {$type} {
        attribute {"dtsResourceId"} {$dtsResourceId},
        attribute {"dbName"} {$dbName}
      }
};