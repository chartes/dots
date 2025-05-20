xquery version "3.1";

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

declare updating %private function del_doc:deleteDocInDb($dbName as xs:string, $docId) {
  let $path := utils_dots:findPath($dbName, $docId)
  return
    db:delete($dbName, $path)
};

declare updating %private function del_doc:deleteFragments($dbName as xs:string, $docId as xs:string) {
  delete nodes db:get($dbName, $G:fragmentsRegister)//dots:fragment[@resourceId = $docId]
};

declare updating %private function del_doc:changeTotalChildren($dbName as xs:string, $parentIds) {
  for $parentId in $parentIds
  let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentId]
  let $totalChildren := $coll/@totalChildren
  return
    replace value of node $totalChildren with (xs:integer($totalChildren) - 1)
};







