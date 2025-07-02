xquery version "4.0";

module namespace utils_dots = "utils_dots"; 

import module namespace G = "globals";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function utils_dots:getIdProject($dbName as xs:string) {
  normalize-space(db:get($dbName, $G:resourcesRegister)//dots:collection[not(@parentIds)]/@dtsResourceId)
};

(:~ This function retrieves the name of the database to which the document identified by $resourceId belongs 
: @param $resourceId document identifier
: @return db name
:)
declare function utils_dots:getDbName($resourceId as xs:string) {
  normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $resourceId]/@dbName)
};

declare function utils_dots:getDocument($dbName as xs:string, $resourceId as xs:string) {
  if (db:get($dbName)/tei:TEI[@xml:id = $resourceId])
  then db:get($dbName)/tei:TEI[@xml:id = $resourceId]
  else 
    db:get($dbName)/node() ! db:path(.)[ends-with(., $resourceId)]
};

declare function utils_dots:findDocId($docPath) {
  let $document := utils_dots:findDocInFolder($docPath) 
  let $resourceId := $document/tei:TEI/@xml:id
  return
    if ($resourceId)
    then $resourceId
    else file:name($docPath)
};

(:~ This function allows retrieving the document with the $resourceId identifier in the import folder $project_dir_path
: @param $resourceId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return TEI document
:)
declare function utils_dots:findDocInFolder($docPath) {
  doc($docPath)
};

declare function utils_dots:findPath($dbName as xs:string, $resourceId as xs:string) {
  head((
    db:get($dbName)/*:TEI[@xml:id = $resourceId] ! db:path(.)
  ) otherwise (
    db:get($dbName)/node() ! db:path(.)[ends-with(., $resourceId)]
  ))
};

(:~
 : Retrieves the document with the specified id.
 : @param $dbName name of database
 : @param $resourceId resource ID
 : @param $strip strip processing instructions (by default true)
 :)
declare function utils_dots:findPathDoc($dbName as xs:string,
  $resourceId as xs:string,
  $strip as xs:boolean := true()
) as document-node() {
  let $path := utils_dots:findPath($dbName, $resourceId)
  let $doc := db:get($dbName, $path)
  return if($strip) then $doc update {
    delete nodes //processing-instruction()[name() = "xml-stylesheet"]
  } else $doc
};

(:~ This function allows finding the path of a document in the import folder
: @param $resourceId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return string (path to the document)
:)
declare function utils_dots:getPathInFolder($resourceId as xs:string, $project_dir_path) {
  let $doc := collection($project_dir_path)/tei:TEI[@xml:id = $resourceId]
  return
    if ($doc)
    then 
      for $file in file:list($project_dir_path, true())
      where ends-with($file, ".xml")
      where doc(concat($project_dir_path, "/", $file))/tei:TEI[@xml:id = $resourceId]
      return
        $file
    else
      let $listDoc := file:list($project_dir_path, true())
      for $docPath in $listDoc
      where ends-with($docPath, concat($resourceId, ".xml"))
      return
        $docPath
};

(:~ This function allows finding the element <document/> with the $resourceId identifier in the resources register of the db $dbName
: @param $dbName    database name
: @param $resourceId    document identifier
: @return <document/> element
:)
declare function utils_dots:getDocInRegister($dbName as xs:string, $resourceId as xs:string) {
  db:get($dbName, $G:resourcesRegister)//dots:member/node()[@dtsResourceId = $resourceId]
};

declare function utils_dots:getParentIds($dbName as xs:string, $docInRegister as element(dots:document)) {
  for $parentId in tokenize($docInRegister/@parentIds, " ")
  return
    $parentId
};

declare function utils_dots:getRootId() {
  normalize-space(db:get($G:dots)/dots:metadataMap/dots:root/dots:id)
};

declare function utils_dots:getRootTitle() {
  normalize-space(db:get($G:dots)/dots:metadataMap/dots:root/dots:title)
};

declare function utils_dots:getRootDescription() {
  let $desc := db:get($G:dots)/dots:metadataMap/dots:root/dots:description
  return
    normalize-space($desc)
};