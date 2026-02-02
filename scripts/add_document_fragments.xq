xquery version '4.0' ;

import module namespace add_doc = "backend/update/add_document";

declare variable $dbName external := ();
declare variable $docPath external := ();
declare variable $parentId external := ();

add_doc:handleFragmentsAddition($dbName, $docPath)