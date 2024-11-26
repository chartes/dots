xquery version "3.1";

module namespace dots.update = "backend/dots_switcher_update"; 

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

declare updating function dots.update:switcher($dbName) {
  let $switcher := db:get($G:dots, $G:dbSwitcher)/dbSwitch
  let $dateModified := $switcher/metadata/dct:modified
  let $totalProject := $switcher/metadata/totalProjects
  let $members := (
    dots.update:project($dbName),
    dots.update:members($dbName)
  )
  return (
    replace value of node $dateModified with current-dateTime(),
    replace value of node $totalProject with $totalProject + 1,
    insert nodes $members as last into $switcher/member
  )
};

declare %private function dots.update:project($dbName as xs:string) {
  let $dtsResourceId := db:get($dbName, $G:resourcesRegister)//member/collection[not(@parentIds)]/@dtsResourceId
  let $projectInSwitcher := db:get($G:dots)//member/project[@dbName = $dbName]
  where not($projectInSwitcher)
  return <project dtsResourceId="{ $dtsResourceId }" dbName="{$dbName}"/>
};

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
