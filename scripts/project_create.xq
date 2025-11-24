xquery version '4.0' ;

import module namespace script = "script";

declare variable $projectDirPath external := ();
declare variable $topCollectionId external := ();
declare variable $dbName external := ();
declare variable $option external := ();
declare variable $rootId external := "";
declare variable $rootTitle external := "";
declare variable $rootDescription external := "";
declare variable $linkXSL external := "";
declare variable $defaultEngine external := ""; 
declare variable $cacheOption external := false();

for $script in ('../scripts/dots_db_init.xq', if ($option) then '../scripts/dots_registers_delete.xq', '../scripts/project_db_init.xq', 
  '../scripts/project_registers_create.xq', '../scripts/TEI_add_id.xq', '../scripts/dots_switcher_update.xq')
return script:execute(xs:anyURI($script), map {
  'dbName': $dbName,
  'projectDirPath': $projectDirPath,
  'topCollectionId': $topCollectionId,
  'option': $option,
  'rootId': $rootId,
  'rootTitle': $rootTitle,
  'rootDescription': $rootDescription,
  'linkXSL': $linkXSL,
  'defaultEngine': $defaultEngine,
  'cacheOption': $cacheOption
})

