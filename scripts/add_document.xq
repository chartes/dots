xquery version '4.0' ;

import module namespace script = "script";
import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace add_doc = "backend/update/add_document";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $docPath external := ();

for $script in ('../scripts/add_document_database.xq', '../scripts/add_document_fragments.xq', '../scripts/TEI_add_id.xq')
return script:execute(xs:anyURI($script), map {
  'dbName': $dbName,
  'docPath': $docPath
})