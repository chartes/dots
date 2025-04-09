
import module namespace script = "script";
import module namespace add_doc = "backend/update/add_document";

declare variable $dbName external := ();
declare variable $docPath external := ();


if (file:exists($docPath))
then
  (
    add_doc:handleAddition($dbName, $docPath),
    script:success(("Le document a bien été ajouté à la base ", $dbName, ".")) 
  )
else
  script:error("Le fichier n'existe pas.")