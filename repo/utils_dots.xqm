xquery version "4.0";


(:~
 : Module providing utility functions for DoTS.
 : These functions facilitate the retrieval of TEI documents,
 : metadata, paths, and identifiers from a BaseX database or import folder.
: @version 1
: @date 2025-06-30 
: @author École nationale des chartes - Philippe Pons
:)

module namespace utils_dots = "utils_dots"; 

import module namespace G = "globals";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : This functions returns the DTS project identifier (dtsResourceId) for the root collection in the resources register of the given database. 
 : @param $dbName the name of the BaseX database
 : @return the project identifier (dtsResourceId)
:)
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

(:~ TODO: This function indicates if a resource is to be cached.
: @param $resourceId document identifier
: @return result of check
:)
declare function utils_dots:cache(
  $dbName as xs:string,
  $resourceId as xs:string
) as xs:boolean {
  let $project := db:get($G:dots)//dots:project[@dbName = $dbName]
  let $cacheOption := $project/@cacheOption
  return
    if ($cacheOption)
    then xs:boolean($cacheOption)
    else false()
};

(:~
 : This function retrieves a TEI document from the database using its xml:id.
 : @param $dbName the name of the database
 : @param $resourceId the document identifier
 : @return the TEI element
:)
declare function utils_dots:getDocument($dbName as xs:string, $resourceId as xs:string) {
  if (db:get($dbName)/tei:TEI[@xml:id = $resourceId])
  then db:get($dbName)/tei:TEI[@xml:id = $resourceId]
  else 
    db:get($dbName)/node() ! db:path(.)[ends-with(., $resourceId)]
};

(:~
 : This function retrieves the document identifier (xml:id) from a file path.
 : @param $docPath the path to the document file
 : @return the resource ID (xml:id or filename)
:)
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

(:~
 : This function finds the path of a document in the database based on its identifier.
 : @param $dbName the name of the database
 : @param $resourceId the document identifier
 : @return the database path to the document
:)
declare function utils_dots:findPath($dbName as xs:string, $resourceId as xs:string) {
  head((
    db:get($dbName)/*:TEI[@xml:id = $resourceId] ! db:path(.)
  ) otherwise (
    db:get($dbName)/node() ! db:path(.)[ends-with(., $resourceId)]
  ))
};

(:~
 : This function retrieves the document with the specified id.
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

(:~
 : This function extracts all parent identifiers from the @parentIds attribute of a <document> element.
 : @param $dbName the name of the database
 : @param $docInRegister the <dots:document> element
 : @return a sequence of parent identifiers
:)
declare function utils_dots:getParentIds($dbName as xs:string, $docInRegister as element(dots:document)) {
  for $parentId in tokenize($docInRegister/@parentIds, " ")
  return
    $parentId
};

(:~
 : This function retrieves the root identifier of the DTS Collection endpoint.
 : @return the root identifier as a string
:)
declare function utils_dots:getRootId() {
  normalize-space(db:get($G:dots)/dots:metadataMap/dots:root/dots:id)
};

(:~
 : This function retrieves the root title of the DTS Collection endpoint.
 : @return the root title as a string
:)
declare function utils_dots:getRootTitle() {
  normalize-space(db:get($G:dots)/dots:metadataMap/dots:root/dots:title)
};

(:~
 : Retrieves the root description of the DTS Collection endpoint.
 : @return the root description as a string
:)
declare function utils_dots:getRootDescription() {
  let $desc := db:get($G:dots)/dots:metadataMap/dots:root/dots:description
  return
    normalize-space($desc)
};