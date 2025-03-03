xquery version "4.0";

module namespace utils_dots = "utils_dots"; 

import module namespace G = "globals";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~ This function retrieves the name of the database to which the document identified by $docId belongs 
: @param $docId document identifier
: @return db name
:)
declare function utils_dots:findDbName($docId as xs:string) {
  normalize-space(db:get($G:dots)//dots:document[@dtsResourceId = $docId]/@dbName)
};

(:~ This function allows retrieving the document with the $docId identifier in the import folder $project_dir_path
: @param $docId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return TEI document
:)
declare function utils_dots:findDocInFolder($docPath) {
  doc($docPath)
};

declare function utils_dots:findPathDoc($dbName, $docId) {
  if (db:get($dbName)/tei:TEI[@xml:id = $docId])
  then 
    db:path(db:get($dbName)/tei:TEI[@xml:id = $docId] )
  else
    let $doc := db:get($dbName)/node()[ends-with(db:path(.), $docId)]
    return
      db:path($doc)
};

(:~ This function allows finding the path of a document in the import folder
: @param $docId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return string (path to the document)
:)
declare function utils_dots:getPathInFolder($docId as xs:string, $project_dir_path) {
  let $doc := collection($project_dir_path)/tei:TEI[@xml:id = $docId]
  return
    if ($doc)
    then 
      for $file in file:list($project_dir_path, true())
      where ends-with($file, ".xml")
      where doc(concat($project_dir_path, "/", $file))/tei:TEI[@xml:id = $docId]
      return
        $file
    else
      let $listDoc := file:list($project_dir_path, true())
      for $docPath in $listDoc
      where ends-with($docPath, concat($docId, ".xml"))
      return
        $docPath
};