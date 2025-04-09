import module namespace script = "script";

declare variable $projectDirPath external := ();
declare variable $topCollectionId external := ();
declare variable $dbName external := ();
declare variable $option external := ();

for $script in ('../scripts/dots_db_init.xq', if ($option) then '../scripts/dots_registers_delete.xq', '../scripts/project_db_init.xq', 
  '../scripts/project_registers_create.xq', '../scripts/TEI_add_id.xq', '../scripts/dots_switcher_update.xq')
return script:execute(xs:anyURI($script), map {
  'dbName': $dbName,
  'projectDirPath': $projectDirPath,
  'topCollectionId': $topCollectionId,
  'option' : $option
})

