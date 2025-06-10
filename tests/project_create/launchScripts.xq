xquery version "4.0";

import module namespace script = "script";

declare function local:downloadDefaultData() {
  let $url := "https://github.com/chartes/dots_documentation/archive/refs/heads/dev.zip"
  let $zip := fetch:binary($url)
  let $entries  := archive:entries($zip)
  let $contents := archive:extract-binary($zip)
  return 
    for-each-pair($entries, $contents, fn($entry, $content) {
      file:create-dir(replace($entry, "[^/]+$", "")),
      file:write-binary($entry, $content)
    })
};

declare variable $defaultProjectDirPath := concat(file:current-dir(), "dots_documentation-dev/data_test/periodiques/encpos_by_abstract");

declare variable $dbName external := "test";
declare variable $topCollectionId external := "test";
declare variable $projectDirPath external := (local:downloadDefaultData(), $defaultProjectDirPath);
declare variable $options external := map {
  "dbDelete": false(),
  "scriptsToLaunch": "all"  
};

declare %unit:test function local:launchTests() {
  if (map:get($options, "scriptsToLaunch") = "all" )
  then
    for $test in ("../tests/project_create/db_create_test.xq", "../tests/project_create/project_registers_create_test.xq", "../tests/project_create/TEI_add_id_test.xq", "../tests/project_create/dots_switcher_update_test.xq")
    return
      script:execute(xs:anyURI($test), map {
    'dbName': $dbName,
    'projectDirPath': $projectDirPath,
    'topCollectionId': $topCollectionId,
    'option' : $options
  })  
};

()
