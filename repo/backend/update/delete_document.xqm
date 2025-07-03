xquery version "4.0";

(:~  
: This module allows deleting a document to an existing collection.
: @author École nationale des chartes - Philippe Pons
: @since 2025-03-14
: @version  1.0
:)

module namespace del_doc = "backend/update/delete_document";

import module namespace utils_dots = "utils_dots"; 
import module namespace G = "globals";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : This function deletes a document from the DoTS register and database, removes associated fragments, 
 : and updates the metadata of parent collections.
 : @param $dbName the name of the project database
 : @param $docId the identifier of the document to delete
 : @return an updating sequence of operations for deletion and metadata update
:)
declare updating function del_doc:handleDelete($dbName, $docId) {
  let $docInRegister := utils_dots:getDocInRegister($dbName, $docId)
  let $parentIds := utils_dots:getParentIds($dbName, $docInRegister) 
  return
    (
      del_doc:deleteDocInDb($dbName, $docId),
      delete node $docInRegister, 
      del_doc:deleteFragments($dbName, $docId),
      del_doc:changeTotalChildren($dbName, $parentIds)
    )
};

(:~
 : This function deletes the XML document from the database using its path.
 : @param $dbName the name of the project database
 : @param $docId the identifier of the document to delete
 : @return an update operation that deletes the document from the database
:)
declare updating %private function del_doc:deleteDocInDb($dbName as xs:string, $docId) {
  let $path := utils_dots:findPath($dbName, $docId)
  return
    db:delete($dbName, $path)
};

(:~
 : This function deletes all fragments associated with a given document from the fragments register.
 : @param $dbName the name of the project database
 : @param $docId the identifier of the document whose fragments should be deleted
 : @return an update operation that removes matching <dots:fragment> elements
:)
declare updating %private function del_doc:deleteFragments($dbName as xs:string, $docId as xs:string) {
  delete nodes db:get($dbName, $G:fragmentsRegister)//dots:fragment[@resourceId = $docId]
};

(:~
 : This function updates the @totalChildren attribute for each parent collection, decreasing it by 1.
 : @param $dbName the name of the project database
 : @param $parentIds a sequence of parent resource identifiers
 : @return an update operation replacing each collection's totalChildren value
:)
declare updating %private function del_doc:changeTotalChildren($dbName as xs:string, $parentIds) {
  for $parentId in $parentIds
  let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentId]
  let $totalChildren := $coll/@totalChildren
  return
    replace value of node $totalChildren with (xs:integer($totalChildren) - 1)
};

declare updating function del_doc:updateSwitcherDots($dbName as xs:string, $resourceId as xs:string){
  let $resource := db:get($G:dots)/dots:dbSwitch/dots:member/node()[@dtsResourceId = $resourceId]
  return
    delete node $resource
};





