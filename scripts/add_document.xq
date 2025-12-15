xquery version '4.0' ;

import module namespace script = "script";
import module namespace utils_dots = "utils_dots"; 

declare variable $dbName external := ();
declare variable $docPath external := ();
declare variable $parentId external := ();
declare variable $projectDirPath external := "";

for $script in ('../scripts/add_document_database.xq', '../scripts/add_document_fragments.xq', '../scripts/TEI_add_id.xq')
return script:execute(xs:anyURI($script), map {
  'dbName': $dbName,
  'docPath': $docPath,
  'parentId': $parentId,
  'projectDirPath': $projectDirPath
})