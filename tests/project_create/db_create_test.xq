xquery version "4.0";

(:~  
: This module contains unit tests to verify the correct initialization of a DoTS BaseX database from a project directory.
: @author École nationale des chartes - Philippe Pons
: @since 2025-06-02
: @version  1.0
:)

import module namespace G = 'globals';
import module namespace dots.create = "backend/db_create";
import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace dots_error = "error/dots_error"; 

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
: This function downloads the default test data if no `$projectDirPath` is provided by the user.
: @return The default test data is downloaded and extracted into the current directory.
:)
(: declare function local:downloadDefaultData() {
  let $url := "https://github.com/chartes/dots_documentation/archive/refs/heads/dev.zip"
  let $zip := fetch:binary($url)
  let $entries  := archive:entries($zip)
  let $contents := archive:extract-binary($zip)
  return 
    for-each-pair($entries, $contents, fn($entry, $content) {
      file:create-dir(file:temp-dir() || replace($entry, "[^/]+$", "")),
      file:write-binary(file:temp-dir() || $entry, $content)
    })
};

declare variable $defaultProjectDirPath := concat(file:temp-dir(), "dots_documentation-dev/data_test/periodiques/encpos_by_abstract"); :)

declare variable $dbName external;
declare variable $projectDirPath external (: (local:downloadDefaultData(), $defaultProjectDirPath) :);
declare variable $options external ;

(:~
: This function is executed before the test suite. It creates the BaseX database tailored to the needs of DoTS for testing.
: @return The database is created in BaseX.
:)
(: declare %updating %unit:before-module function local:createProjectTest() {
  if (db:exists($dbName)) then () else dots.create:db($dbName, $projectDirPath)
}; :)

(:~
: This test checks whether the BaseX database has been created successfully.
: @return An assertion that the database named $dbName exists.
:)
declare %unit:test function local:dbExists() {
  unit:assert(db:exists($dbName), dots_error:dbError($dbName))
};

(:~
: This test verifies that all XML files in the /data directory are loaded into the database.
: @return An assertion that the number of <TEI> documents in the database matches the number of XML files in the /data directory of the project directory.
:)
declare %unit:test function local:checkNumberDocs() {
  let $docsInDir := count(file:list(concat($projectDirPath, "/data"), true(), "*.xml"))
  let $docsInDb := count(db:get($dbName)/tei:TEI)
  return
    unit:assert-equals($docsInDir, $docsInDb, dots_error:numberDocs($docsInDir, $docsInDb))
};

(:~
: This test checks that the collection structure in the database matches the directory structure in the project directory.
: @return An assertion that the number of collections matches between the /data directory and the database (excluding "metadata").
:)
declare %unit:test function local:checkNumberColls() {
  let $collsInDir := count(file:descendants(concat($projectDirPath, "/data"))[not(ends-with(., ".xml"))])
  let $collsInDb := count(db:dir($dbName, "")[. != "metadata"][. != "dots"][./name() != "resource"])
  return
    unit:assert-equals($collsInDir, $collsInDb, dots_error:numberColls($collsInDir, $collsInDb))
};

(:~
: This test checks whether the metadata folder exists in the database, based on the presence of a /metadata directory in the project directory.
: @return An assertion that the "metadata" collection exists or not, depending on the project directory.
:)
declare %unit:test function local:checkMetada() {
  if (file:exists(concat($projectDirPath, "/metadata")))
  then
    unit:assert(exists(db:dir($dbName, "metadata")), dots_error:metadata("dir"))
  else 
    unit:assert(not(exists(db:dir($dbName, "metadata"))), dots_error:metadata("db"))
};

(:~
: This test verifies that all metadata files from the /metadata directory are loaded into the database.
: @return An assertion that the number of files in the "metadata" collection matches the number of files in the project directory.
:)
declare %unit:test function local:checkNumberDocsInMetadata() {
  let $docsInDir := count(file:list(concat($projectDirPath, "/metadata"), true()))
  let $docsInDb := count(db:get($dbName, "/metadata"))
  return
    unit:assert-equals($docsInDir, $docsInDb, dots_error:docsInMetadata($docsInDir, $docsInDb))
};

(:~
: This test ensures that the dots metadata mapping file exists both in the database and in the project directory. It is only run if a /metadata directory exists.
: @return Two assertions: the presence of "dots_metadata_mapping.xml" in both the database and the project directory.
:)
declare %unit:test function local:checkMetadataMapping() {
  if (file:exists(concat($projectDirPath, "/metadata")))
  then
    (
      unit:assert(exists(db:get($dbName, "metadata/dots_metadata_mapping.xml")), dots_error:metadata_mapping($dbName, "")),
      unit:assert(file:exists(concat($projectDirPath, "/metadata/dots_metadata_mapping.xml")), dots_error:metadata_mapping("", $projectDirPath) )
    )
};

(:~
: This function is executed after the test suite. It deletes the BaseX database created for testing.
: @return The database is removed from the system.
:)
(: declare %updating %unit:after-module function local:deleteProjectTest() {
  if ($options = true()) 
  then 
    dots.delete:handle($dbName, "true")
}; :) 

(:~
: This function deletes the default test data if it exists.
: @return The default test data directory is removed from the current directory.
:)
(: declare %unit:after-module function local:deleteDefaultDataFile() {
  let $defaultDataFile := concat(file:temp-dir(), "dots_documentation-dev")
  where file:exists($defaultDataFile)
  return
    file:delete($defaultDataFile, true())
}; :)

()


