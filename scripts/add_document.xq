xquery version '4.0' ;

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace script = "script";
import module namespace add_doc = "backend/update/add_document";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $docPath external := ();


if (file:exists($docPath))
then
  let $parentIds := 
    let $path := substring-after($docPath, "data/")
    return
      let $collId := if (contains($path, "/")) then functx:substring-after-last(replace($path, "/", ""), "/") else "project"
      return $collId
  let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentIds]
  return
    if ($parentIds = "project" or $coll)
    then
      (
        add_doc:handleAddition($dbName, $docPath),
        script:success(("Le document a bien été ajouté à la base ", $dbName, ".")) 
      )
     else script:error("La collection n'existe pas.")
else
  script:error("Le fichier n'existe pas.")