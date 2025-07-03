xquery version '4.0' ;

import module namespace script = "script";

declare variable $dbName external := ();
declare variable $docPath external := ();

for $script in ('../scripts/add_document_database.xq', '../scripts/add_document_fragments.xq', '../scripts/TEI_add_id.xq')
return script:execute(xs:anyURI($script), map {
  'dbName': $dbName,
  'docPath': $docPath
})