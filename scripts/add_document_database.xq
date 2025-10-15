xquery version '4.0' ;

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace script = "script";
import module namespace add_doc = "backend/update/add_document";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $dbName external;
declare variable $docPath external;
declare variable $parentId external := ();

if (doc($docPath)/tei:TEI)
then
  let $parent := 
    if ($parentId = "") 
    then G:getTopCollectionId($dbName) 
    else 
      db:list($dbName)[contains(., concat($parentId, "/"))][1]
  return
    if ($parent)
    then 
      let $parentPath := if (contains($parent, "/")) then functx:substring-before-last($parent, "/") else $parent
      let $docName := functx:substring-after-last($docPath, "/")
      return
        if (db:exists($dbName, concat($parentPath, "/", $docName)))
        then script:error(concat("Le document ", $docName, " est déjà présent dans la base."))
        else
          (
            add_doc:handleAddition($dbName, $docPath, $parentPath),
            script:success(("Le document a bien été ajouté à la base '", $dbName, "'.")) 
          )
    else script:error(concat("La collection ", $parentId, " n'existe pas.")) 
else
  script:error(concat("Le fichier '", $docPath, "' n'existe pas."))
  
  
  