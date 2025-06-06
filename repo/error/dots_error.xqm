xquery version "4.0";

module namespace dots_error = "error/dots_error"; 
import module namespace add_doc = "backend/update/add_document";

declare function dots_error:process($data) {
  if(empty($data)) then (
    error(xs:QName('add_doc:empty'), '* ❌ Error : no data specified')
  ) else (
    $data
  )
};

declare function dots_error:pathError($value as xs:boolean) {
  if ($value)
  then ()
  else
    error(xs:QName('update_doc_ctt:path'), '* ❌ Error : paths are different')
};

declare function dots_error:dbError($dbName as xs:string) {
  error(xs:QName('no_db'), concat("* ❌ Error : the database '", $dbName, "' doesn't exist."))
};

declare function dots_error:numberDocs($docsInDir as xs:integer, $docsInDb as xs:integer) {
  error(xs:QName('numberDocs'), concat("* ❌ Error : mismatch in number of TEI documents: project directory = ", $docsInDir, ", database = ", $docsInDb, "."))
};

declare function dots_error:numberColls($collsInDir as xs:integer, $collsInDb as xs:integer) {
  error(xs:QName('numberColls'), concat("* ❌ Error : mismatch in number of collections: project directory = ", $collsInDir, ", database = ", $collsInDb, "."))
};

declare function dots_error:metadata($options as xs:string) {
  (
    if ($options = "dir") then error(xs:QName('metadata'), concat("* ❌ Error : metadata directory exists in the project directory but is missing in the database.")),
    if ($options = "db")then error(xs:QName('metadata'), concat("* ❌ Error : metadata directory is absent in the project directory but present in the database."))
  )
};

declare function dots_error:docsInMetadata($docsInDir as xs:integer, $docsInDb as xs:integer) {
  error(xs:QName('metadata'), concat("* ❌ Error : mismatch in number of metadata documents: directory = ", $docsInDir, ", database = ", $docsInDb, "."))
};

declare function dots_error:metadata_mapping($dbName, $projectDirPath ) {
  (
    if ($dbName) then error(xs:QName('metadata_mapping'), concat("* ❌ Error :  dots metadata mapping file not found in database: ", $dbName)),
    if ($projectDirPath) then error(xs:QName('metadata_mapping'), concat("* ❌ Error :  dots metadata mapping file not found in directory: ", $projectDirPath))
  )
};






