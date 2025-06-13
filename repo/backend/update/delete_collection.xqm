xquery version "4.0";

(:~  
: This module allows deleting a collection.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-11
: @version  1.0
:)

module namespace del_coll = "backend/update/delete_collection";

import module namespace utils_dots = "utils_dots"; 
import module namespace G = "globals";
import module namespace del_doc = "backend/update/delete_document";

declare default element namespace "https://github.com/chartes/dots/";

declare updating function del_coll:handleDeleteColl($dbName as xs:string, $collectionId as xs:string, $option as xs:boolean) {
  let $collection := db:get($dbName, $G:resourcesRegister)//member/collection[@dtsResourceId = $collectionId]
  let $docInColl := db:get($dbName, $G:resourcesRegister)//member/document[tokenize(@parentIds) = $collectionId]
  let $parentId := $collection/@parentIds
  return
    (
      delete node $collection,
      del_coll:changeParentTotalChildren($dbName, $parentId, count($docInColl)),
      del_coll:handleDocInColl($dbName, $collection, $docInColl, $option),
      del_doc:updateSwitcherDots($dbName, $collectionId)
    )
};

declare updating %private function del_coll:changeParentTotalChildren($dbName as xs:string, $parentId as xs:string, $numberDocs as xs:integer) {
  let $parent := db:get($dbName, $G:resourcesRegister)//member/collection[@dtsResourceId = $parentId]
  let $totalChildren := $parent/@totalChildren
  let $newTotalChildren := (xs:integer($totalChildren) - 1 + $numberDocs)
  return
    replace value of node $totalChildren with $newTotalChildren 
  };

declare updating %private function del_coll:handleDocInColl($dbName as xs:string, $collection as element(collection), $docInColl, $option as xs:boolean) {
  for $document in $docInColl
  let $countDoc := count($docInColl)
  return
    if ($option)
    then 
      let $docId := $document/@dtsResourceId
      return
        del_doc:handleDelete($dbName, $docId)
    else
      let $parentDoc := $document/@parentIds
      let $parentCollId := $collection/@parentIds
      let $collId := $collection/@dtsResourceId
      return
        (
          replace value of node $parentDoc with replace($parentDoc, $collId, $parentCollId)
        )
};













