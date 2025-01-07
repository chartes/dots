
import module namespace add_collection = "backend/add_collections/project_add_collections"; 
import module namespace script = "script";

declare variable $dbName external := ();
declare variable $csvPath external := ();
declare variable $metadataMapping external := ();

if (not($dbName and $csvPath)) 
then (
  script:error("You must give a dbName and / or a csvPath")
)
else
  (
    add_collection:addColl($dbName, $csvPath, $metadataMapping),
    script:success(concat("The collection(s) have been successfully added to the db ", $dbName))
  )