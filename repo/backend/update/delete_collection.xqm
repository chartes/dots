xquery version "4.0";

(:~ This module provides functions to delete a collection from the DoTS resource registry 
 : stored in a BaseX database. It ensures proper update of the parent collection, 
 : handles documents within the deleted collection (either by deleting or reassigning them), 
 : and keeps the DTS switching mechanism consistent.
 : @author École nationale des chartes – Philippe Pons
 : @since 2025-06-11
 : @version 1.0
:)

module namespace del_coll = "backend/update/delete_collection";

import module namespace utils_dots = "utils_dots"; 
import module namespace G = "globals";
import module namespace del_doc = "backend/update/delete_document";

declare default element namespace "https://github.com/chartes/dots/";

(:~ This function allows deleting a collection from the DTS resource registry in the BaseX database. 
: It removes the collection node, updates the parent collection's child count, 
: handles child documents (deletion or reassignment), and updates the DoTS switcher.
: @param $dbName          name of the BaseX database
: @param $collectionId    identifier (dtsResourceId) of the collection to delete
: @param $option          boolean: if true, delete the documents in the collection; 
:                         if false, reassign them to the parent collection
: @return database updates (delete node, update attributes, trigger document deletion or reassignment)
:)
declare updating function del_coll:handleDeleteColl($dbName as xs:string, $collectionId as xs:string, $option as xs:boolean) {
  let $collection := db:get($dbName, $G:resourcesRegister)//member/collection[@dtsResourceId = $collectionId]
  let $docInColl := db:get($dbName, $G:resourcesRegister)//member/document[tokenize(@parentIds) = $collectionId]
  let $parentId := $collection/@parentIds
  return
    (
      delete node $collection,
      del_coll:changeParentTotalChildren($dbName, $parentId, count($docInColl)),
      del_doc:updateSwitcherDots($dbName, $collectionId)
    )
};

(:~ This function updates the totalChildren attribute of a parent collection after deleting one of its children.
 : It subtracts 1 (the deleted collection) and adds the number of documents reassigned to the parent.
 : @param $dbName        name of the BaseX database
 : @param $parentId      identifier (dtsResourceId) of the parent collection
 : @param $numberDocs    number of documents previously in the deleted collection
 : @return replacement of the value of totalChildren attribute
:)
declare updating %private function del_coll:changeParentTotalChildren($dbName as xs:string, $parentId as xs:string, $numberDocs as xs:integer) {
  let $parent := db:get($dbName, $G:resourcesRegister)//member/collection[@dtsResourceId = $parentId]
  let $totalChildren := $parent/@totalChildren
  let $newTotalChildren := (xs:integer($totalChildren) - 1 + $numberDocs)
  return
    replace value of node $totalChildren with $newTotalChildren 
  };

(:~ This function handles the documents that belonged to a deleted collection.
 : If $option is true, the documents are deleted.
 : If $option is false, the documents are reassigned to the parent of the deleted collection.
 : @param $dbName        name of the BaseX database
 : @param $collection    the <collection> element that is being deleted
 : @param $docInColl     sequence of <document> elements that belong to the collection
 : @param $option        boolean: true = delete documents; false = reassign to parent
 : @return database updates (delete or reassign documents)
:)
declare updating function del_coll:handleDocInColl($dbName as xs:string, $collectionId as xs:string, $option as xs:boolean) {
  for $document in db:get($dbName, $G:resourcesRegister)//document[tokenize(@parentIds) = $collectionId]
  let $resourceId := $document/@dtsResourceId
  let $pathDoc := utils_dots:findPath($dbName, $resourceId)
  let $parentDoc := $document/@parentIds
  let $parentCollId := db:get($dbName, $G:resourcesRegister)//collection[@dtsResourceId = $collectionId]/@parentIds
  return
    (
      replace value of node $parentDoc with replace($parentDoc, $collectionId, $parentCollId),
      db:delete($dbName, $pathDoc),
      db:put($dbName, $document, replace($pathDoc, concat($collectionId, "/"), "/"))
    )
  (: for $document in $docInColl
  let $docId := $document/@dtsResourceId
  return
    if ($option)
    then 
      del_doc:handleDelete($dbName, $docId)
    else
      let $parentDoc := $document/@parentIds
      let $parentCollId := $collection/@parentIds
      let $collId := $collection/@dtsResourceId
      let $pathDoc := utils_dots:findPath($dbName, $docId)
      return
        (
          replace value of node $parentDoc with replace($parentDoc, $collId, $parentCollId),
          db:delete($dbName, $pathDoc),
          db:put($dbName, $document, replace($pathDoc, concat($collId, "/"), "/"))
        ) :)
};













