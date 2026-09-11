xquery version "4.0";

(:~  
: This module allows TODO
: @author École nationale des chartes - Philippe Pons
: @since 2025-10-20
: @version  1.0
:)

module namespace delete_doc_from_coll = "backend/update/delete_doc_from_collection"; 

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace store_clear = "backend/update/store_clear";

declare namespace dots = "https://github.com/dots-suite/dots";

declare updating function delete_doc_from_coll:handleDeletion($dbName as xs:string, $document as element(dots:document), $collection as element(dots:collection)) {
  delete_doc_from_coll:updateDocumentElement($dbName, $document, $collection),
  delete_doc_from_coll:decreaseTotalChildren($dbName, $collection),
  store_clear:clear($dbName, $document/@dtsResourceId)
};

declare updating function delete_doc_from_coll:updateDocumentElement($dbName as xs:string, $document as element(dots:document), $collection as element(dots:collection)) {
  let $parentIds := $document/@parentIds
  return
    if (count(tokenize($parentIds)) > 1)
    then replace value of node $parentIds with normalize-space(replace($parentIds, $collection/@dtsResourceId, ""))
    else
      let $projectId := utils_dots:getIdProject($dbName)
      return
        replace value of node $parentIds with $projectId
};

declare updating function delete_doc_from_coll:decreaseTotalChildren($dbName as xs:string, $collection as element(dots:collection)) {
  let $totalChildren := $collection/@totalChildren
  return
    replace value of node $totalChildren with (xs:integer($totalChildren) - 1)
};



