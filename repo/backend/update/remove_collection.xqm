xquery version "4.0";

module namespace remove_coll = "backend/update/remove_collection"; 

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace del_doc = "backend/update/delete_document";

declare default element namespace "https://github.com/chartes/dots/";

declare updating function remove_coll:remove_collection(
  $dbName as xs:string,
  $collId as xs:string
) {
  let $coll := db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId = $collId]
  let $parentId := $coll/@parentIds
  return
    (
      remove_coll:remove_collection_from_resources_register($dbName, $coll),
      let $subColls := db:get($dbName, $G:resourcesRegister)//collection[@parentIds = $collId]
      let $countSubColls := count($subColls)
      let $countDocs := count(db:list($dbName)[ends-with(functx:substring-before-last(., "/"), $collId)])
      return
        (remove_coll:increment_totalChildren($dbName, $parentId, ($countSubColls + $countDocs)),
        for $subColl in $subColls
        let $resourceId := $subColl/@dtsResourceId
        return
          remove_coll:update_resource_parentIds($dbName, $resourceId, $collId, $parentId)
        ),
      remove_coll:handle_documents_in_collection($dbName, $collId, $parentId)    ,
      del_doc:updateSwitcherDots($dbName, $collId)  
    )
};

declare updating function remove_coll:remove_collection_from_resources_register(
  $dbName as xs:string,
  $coll as element(collection)
) {
 delete node $coll
};

(:~~~~~~~~~~~~~~~~
Update des sous-collections (le cas échéant)
~~~~~~~~~~~~~~~~:)

(:  
: @todo ajouter une option pour spécifier, selon le type de collection, s'il faut SUPPRIMER ou REMPLACER la valeur de @parentIds
:)
declare updating function remove_coll:update_resource_parentIds(
  $dbName as xs:string,
  $resourceId as xs:string, 
  $collId as xs:string, 
  $parentCollId as xs:string
) {
let $resource := db:get($dbName, $G:resourcesRegister)//node()[@dtsResourceId=$resourceId]
let $parentIds := tokenize($resource/@parentIds)
let $changeParentIds :=
  for $parentId in $parentIds 
  return
    if ($parentId = $collId) then $parentCollId else $parentId
let $new :=
  if ($parentCollId = "") then string-join($changeParentIds) else $changeParentIds
let $newParentIds :=
  for $parentId in $parentIds 
  return
    if ($parentId = $collId) then $parentCollId else $parentId
return
  replace value of node $resource/@parentIds with $newParentIds
};

declare updating function remove_coll:increment_totalChildren(
  $dbName as xs:string,
  $collId as xs:string,
  $num as xs:integer := 0
) {
  let $totalChildren := db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId=$collId]/@totalChildren
  let $newTotalChildren := xs:integer($totalChildren) + $num - 1
  return
    replace value of node $totalChildren with $newTotalChildren
};

declare updating function remove_coll:handle_documents_in_collection(
  $dbName as xs:string, 
  $collId as xs:string,
  $parentCollId as xs:string) {
    for $doc in db:get($dbName, $G:resourcesRegister)//document[tokenize(@parentIds) = $collId]
    let $resourceId := $doc/@dtsResourceId
    let $docInDB := 
      if (db:get($dbName)/*:TEI[@xml:id=$resourceId])
      then db:get($dbName)/*:TEI[@xml:id=$resourceId]
      else db:list($dbName)[ends-with(., $resourceId)]
    let $docPath := db:path($docInDB)
    let $path := functx:substring-before-last($docPath, "/")
    let $docName := functx:substring-after-last($docPath, "/")
    return
      if (ends-with($docPath, concat($collId, "/", $docName)))
      then 
        (
          remove_coll:update_resource_parentIds($dbName, $resourceId, $collId, $parentCollId)
        )
      else 
       remove_coll:update_resource_parentIds($dbName, $resourceId, $collId, "") 
};

declare updating function remove_coll:move_documents(
  $dbName as xs:string,
  $source as xs:string,
  $target as xs:string
) {
  db:rename($dbName, $source, $target)
};

(: remove_coll:remove_collection("encpos", "ENCPOS_1972") :)

