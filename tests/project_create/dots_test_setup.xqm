xquery version "4.0";

(:~  
:
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-10
: @version  1.0
:)

module namespace test.setup = "test_setup";

import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete"; 

(: declare function test.setup:downloadDefaultData() {
  let $url := "https://github.com/chartes/dots_documentation/archive/refs/heads/dev.zip"
  let $zip := fetch:binary($url)
  let $entries  := archive:entries($zip)
  let $contents := archive:extract-binary($zip)
  return 
    for-each-pair($entries, $contents, fn($entry, $content) {
      file:create-dir(replace($entry, "[^/]+$", "")),
      file:write-binary($entry, $content)
    })
}; :)

(: declare variable $test.setup:defaultProjectDirPath := concat(file:current-dir(), "dots_documentation-dev/data_test/periodiques/encpos_by_abstract"); :)

(: declare variable $test.setup:dbName external := "test";
declare variable $test.setup:projectDirPath external := (test.setup:downloadDefaultData(), $test.setup:defaultProjectDirPath);
declare variable $test.setup:options external := map {
  "dbCreate": true()
}; :)

(:~
: This function is executed before the test suite. It creates the BaseX database tailored to the needs of DoTS for testing.
: @return The database is created in BaseX.
:)
declare %updating %unit:before function test.setup:createProjectTest($dbName as xs:string, $projectDirPath as xs:string) {
  if (db:exists($dbName)) then () else dots.create:db($dbName, $projectDirPath)
};

(:~
: This function is executed after the test suite. It deletes the BaseX database created for testing.
: @return The database is removed from the system.
:)
declare %updating %unit:after function test.setup:deleteProjectTest($dbName as xs:string, $options) {
  if (map:get($options, "dbCreate") = true()) 
  then 
    dots.delete:handle($dbName, "true")
}; 

declare %unit:after function test.setup:deleteDefaultDataFile() {
  let $defaultDataFile := concat(file:current-dir(), "dots_documentation-dev")
  where file:exists($defaultDataFile)
  return
    file:delete($defaultDataFile, true())
};