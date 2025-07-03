xquery version '4.0' ;

import module namespace script = "script";
import module namespace del_doc = "backend/update/delete_document";
import module namespace utils_dots = "utils_dots";

declare variable $dbName external := ();
declare variable $docId external := ();

let $doc := utils_dots:findPath($dbName, $docId)
return
  if ($doc)
  then 
    (
      del_doc:handleDelete($dbName, $docId),
      script:success(("Le document ", $docId, " a bien été supprimé de la base ", $dbName, ".")) 
    )
  else
    script:error(concat("Le document ", $docId, " n'existe pas."))