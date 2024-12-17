xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS d'ajouter un ou plusieurs documents à une db
: @author École nationale des chartes
: @since 2024-10-16
: @version  1.0
:)
module namespace dots.add_doc = "backend/project_add_document";

import module namespace G = "globals";
import module namespace functx = 'http://www.functx.com';

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function dots.add_doc:addDocsToDb($dbName as xs:string, $docs as xs:string, $path as xs:string, $csvPath as xs:string, $separator as xs:string) {
  let $csv := if ($csvPath) then csv:doc($csvPath, map {
    "header": true(),
    "separator": $G:separator
  })
  for $docs in collection($path)/tei:TEI
  return
    ""
};
