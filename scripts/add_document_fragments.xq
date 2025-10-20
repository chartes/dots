xquery version '4.0' ;

import module namespace add_doc = "backend/update/add_document";

declare variable $dbName external := ();
declare variable $docPath external := ();
declare variable $parentId external := ();

(: if ($docExists)
then script:error("Le document existe déjà dans la db")
else :)
  add_doc:handleFragmentsAddition($dbName, $docPath)