declare variable $project_dir_path external;
declare variable $top_collection_id external;
declare variable $db_name external;

let $eval := function($script) {
  let $id := job:eval(
    xs:anyURI($script),
    map {
      'dbName': $db_name,
      'projectDirPath': $project_dir_path,
      'topCollectionId': $top_collection_id
    },
    map { 'cache': true() }
  )
  return (job:wait($id), job:result($id))
}
return (
  $eval('dots_db_init.xq'),
  $eval('project_db_init.xq'),
  $eval('project_registers_create.xq'),
  $eval('dots_registers_update.xq'),
  $eval('dots_switcher_update.xq')
)
