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
  let $pathInData := substring-after($docPath, "data/")
  let $parentIds := 
    let $pathCollection := functx:substring-before-last($pathInData, "/")
    let $collectionId := if (contains($pathCollection, "/")) then functx:substring-after-last($pathCollection, "/") else $pathCollection
    return
      $collectionId 
  return
    let $coll := 
      if ($parentIds = "") 
      then "project" 
      else db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentIds]
    return
      if ($parentIds = "project" or $coll)
      then
        (
          add_doc:handleAddition($dbName, $docPath),
          if (db:get($dbName, $pathInData)) 
          then script:warning(concat("Le document existait déjà et a été mis à jour dans la base '", $dbName, "'.")) 
          else script:success(("Le document a bien été ajouté à la base '", $dbName, "'.")) 
        )
      else script:error("La collection n'existe pas.")
else
  script:error(concat("Le fichier '", $docPath, "' n'existe pas."))
  
  
  