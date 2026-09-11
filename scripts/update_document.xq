xquery version '4.0';

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";
import module namespace script = "script";
import module namespace dots_error = "error/dots_error"; 

declare namespace dots = "https://github.com/dots-suite/dots";

declare variable $dbName external := ();
declare variable $docPath external := ();
declare variable $docId external := ();


if (db:exists($dbName))
then
  if (file:exists($docPath))
  then
    if (db:get($dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $docId])
    then
      for $script in ('../scripts/delete_document.xq', '../scripts/add_document_database.xq', '../scripts/add_document_fragments.xq', '../scripts/TEI_add_id.xq')
      return script:execute(xs:anyURI($script), map {
        'dbName': $dbName,
        'docPath': $docPath,
        'docId': $docId
      }) 
    else dots_error:noDocument($docId)
  else dots_error:fileProblem()
else dots_error:dbError($dbName)  
  
  