
import module namespace script = "script";
import module namespace add_doc = "backend/update/add_document";

declare variable $dbName external := ();
declare variable $docPath external := ();

add_doc:handleAddition($dbName, $docPath) 
