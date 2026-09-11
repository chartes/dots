xquery version "4.0";

(:~  
: This module allows TODO
: @author École nationale des chartes - Philippe Pons
: @since 2025-10-20
: @version  1.0
:)

module namespace doc_to_coll = "backend/update/add_doc_to_collection"; 

import module namespace G = "globals";
import module namespace store_clear = "backend/update/store_clear";

declare namespace dots = "https://github.com/dots-suite/dots";

declare updating function doc_to_coll:handleAddition($dbName as xs:string, $document as element(dots:document), $collection as element(dots:collection)) {
  doc_to_coll:updateDocumentElement($dbName, $document, $collection),
  doc_to_coll:incrementTotalChildren($dbName, $collection),
  store_clear:clear($dbName, $document/@dtsResourceId),
  store_clear:clear($dbName, $collection/@dtsResourceId)
};

declare updating function doc_to_coll:updateDocumentElement($dbName as xs:string, $document as element(dots:document), $collection as element(dots:collection)) {
  let $parentIds := $document/@parentIds
  return
    replace value of node $parentIds with concat($parentIds, " ", $collection/@dtsResourceId)      
};

declare updating function doc_to_coll:incrementTotalChildren($dbName as xs:string, $collection as element(dots:collection)) {
  let $totalChildren := $collection/@totalChildren
  return
    replace value of node $totalChildren with (xs:integer($totalChildren) + 1)
};

