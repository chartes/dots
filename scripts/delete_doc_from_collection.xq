xquery version '4.0' ;

import module namespace G = "globals";
import module namespace script = "script";
import module namespace delete_doc_from_coll = "backend/update/delete_doc_from_collection"; 

declare namespace dots = "https://github.com/dots-suite/dots";

declare variable $dbName external := ();
declare variable $docId external := ();
declare variable $collectionId external := ();

let $document := db:get($dbName, $G:resourcesRegister)//dots:document[@dtsResourceId = $docId]
let $collection := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $collectionId]
return
  if ($document)
  then
    if ($collection)
    then
      let $currentCollections := $document/tokenize(@parentIds)
      return
        if ($currentCollections = $collectionId)
        then
          (
            delete_doc_from_coll:handleDeletion($dbName, $document, $collection),
            script:success(concat("Le document '", $docId, "' a bien été supprimé de la collection '", $collectionId, "'."))
          )
          
        else 
          script:error(concat("Le document '", $docId, "' n'appartient pas à la collection ", $collectionId))
    else
      script:error(concat("La collection '", $collectionId, "' n'est pas présente dans la db '", $dbName, "'."))
  else 
    script:error(concat("Le document '", $docId, "' n'est pas présent dans la db '", $dbName, "'."))
    
