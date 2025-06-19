xquery version '4.0' ;

import module namespace G = "globals";
import module namespace script = "script";
import module namespace update_metadata = "backend/update/update_metadata";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $projectDirPath external := ();

if (db:exists($dbName))
then
  if (file:exists($projectDirPath))
  then
    let $checkMetadataInDb := db:get($dbName, $G:metadata)
    return
      (
        if ($checkMetadataInDb)
        then
          update_metadata:deleteMetadata($dbName)
        else script:warning(concat("'metadata/' directory not found in the database '", $dbName, "'")),
        let $metadataPathFile := concat($projectDirPath, "/", $G:metadata)
        for $document in file:list($metadataPathFile, true())
        where not(file:is-dir(concat($metadataPathFile, "/", $document)))
        return
          update_metadata:addNewMetadataDocument($dbName, $metadataPathFile, $document),
        if ($checkMetadataInDb)
        then script:success(concat("The 'metadata/' directory of the database '", $dbName, "' has been updated.")) 
        else script:success(concat("The 'metadata/' directory has been added to the database '", $dbName, "'."))
      )
  else script:error(concat("the directory '", $projectDirPath, "' doesn't exist."))
else script:error(concat("the database '", $dbName, "' doesn't exist."))
  
  
  


  