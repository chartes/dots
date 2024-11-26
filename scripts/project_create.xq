import module namespace script = "script";

declare variable $projectDirPath external := ();
declare variable $topCollectionId external := ();
declare variable $dbName external := ();

if (not($projectDirPath and $topCollectionId and $dbName)) then (
  script:usage(
    static-base-uri(),
    "Load a project import folder in basex.",
    ([ "projectDirPath", "absolute path to import folder", "/absolute/path/to/import/folder" ],
     [ "topCollectionId", "project root id", "theater" ],
     [ "dbName", "basex db project name", "theater" ])
  )
) else (
  let $variables := map {
    'dbName': $dbName,
    'projectDirPath': $projectDirPath,
    'topCollectionId': $topCollectionId
  }
  return (
    script:execute('dots_db_init.xq', $variables),
    script:execute('project_db_init.xq', $variables),
    script:execute('project_registers_create.xq', $variables),
    script:execute('dots_registers_update.xq.xq', $variables),
    script:execute('dots_switcher_update.xq', $variables)
  )
)
