xquery version "4.0";

(:~ This module provides functions to remove a collection from the DoTS resource registry 
 : stored in a BaseX database. It ensures proper update of the parent collection, 
 : handles documents within the deleted collection (either by deleting or reassigning them), 
 : and keeps the DTS switching mechanism consistent.
 : @author École nationale des chartes – Philippe Pons
 : @since 2025-10-12
 : @version 1.0
:)

module namespace remove_coll = "backend/update/remove_collection"; 

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace del_doc = "backend/update/delete_document";
import module namespace store_clear = "backend/update/store_clear";

declare default element namespace "https://github.com/chartes/dots/";

declare updating function remove_coll:remove_collection(
  $dbName            as xs:string,
  $collId            as xs:string,
  $deleteResources
) {
  let $coll := db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId = $collId]
  let $parentId := $coll/@parentIds
  return
    (
      store_clear:clear($dbName, $parentId),
      remove_coll:remove_collection_from_resources_register($dbName, $coll),
      if ($deleteResources)
      then 
        (
          remove_coll:increment_totalChildren($dbName, $parentId),
          let $descendants := remove_coll:findDescendants($dbName, $collId)
          return
            (
              remove_coll:updateTotalChildrenValue($dbName, $descendants),
              for $resourceKey in map:keys($descendants)
              let $type := map:get($descendants, $resourceKey)?type
              return
                if ($type = "document")
                then del_doc:handleDelete($dbName, $resourceKey, false())
                else 
                  let $coll := db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId = $resourceKey]
                  return
                    (
                      remove_coll:remove_collection_from_resources_register($dbName, $coll),
                      del_doc:updateSwitcherDots($dbName, $resourceKey)  
                    )
            )
        )
      else
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
        remove_coll:handle_documents_in_collection($dbName, $collId, $parentId),
        del_doc:updateSwitcherDots($dbName, $collId)  
    )
};

declare updating function remove_coll:remove_collection_from_resources_register(
  $dbName           as xs:string,
  $coll             as element(collection)
) {
 delete node $coll
};

(:~~~~~~~~~~~~~~~~
Update des sous-collections (le cas échéant)
~~~~~~~~~~~~~~~~:)

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

declare function remove_coll:findDescendants(
  $dbName  as xs:string,
  $collId  as xs:string
) {
  map:merge((
    for $resource in db:get($dbName, $G:resourcesRegister)//node()[tokenize(@parentIds) = $collId]
    let $resourceType := $resource/name()
    let $resourceId := normalize-space($resource/@dtsResourceId)
    let $parentIds := $resource/@parentIds
    return
      (
        map:entry(
        $resourceId, 
        map:merge((
          map:entry("type", $resourceType  ),
          map:entry("parentIds", normalize-space($parentIds))
        ))
        ),
        if ($resourceType = "collection")
        then remove_coll:findDescendants($dbName, $resourceId)
      )
  ))
};

declare updating function remove_coll:updateTotalChildrenValue(
  $dbName as xs:string,
  $map
) {
  let $all-tokens := 
    for $entry in map:keys($map)
    let $parentIds := $map($entry)("parentIds")
    return tokenize($parentIds, '\s+')
  return 
    for $token in distinct-values($all-tokens)
    where not(exists(map:get($map, $token)))
    let $countToken := count($all-tokens[. = $token])
    let $coll := db:get($dbName, $G:resourcesRegister)//*:collection[@dtsResourceId = $token]
    let $totalChildren := $coll/@totalChildren
    return 
      replace value of node $totalChildren with xs:integer($coll/@totalChildren - $countToken)
};

