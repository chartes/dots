xquery version "4.0";

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";
import module namespace script = "script";
import module namespace add_doc = "backend/update/add_document";
import module namespace del_doc = "backend/update/delete_document";
import module namespace functx = 'http://www.functx.com';

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $docPath external := ();


if (file:exists($docPath))
then
  (
    let $docId := utils_dots:findDocId($docPath)
    let $doc := utils_dots:findPath($dbName, $docId)
    return
      if ($doc)
      then 
        (
          del_doc:handleDelete($dbName, $docId),
          let $parentIds := 
            let $pathInData := substring-after($docPath, "data/")
            let $pathCollection := functx:substring-before-last($pathInData, "/")
            let $collectionId := if (contains($pathCollection, "/")) then functx:substring-after-last($pathCollection, "/") else $pathCollection
            return
              $collectionId 
          return 
              let $coll := if ($parentIds = "") then "project" else db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentIds]
              return
                if ($parentIds = "project" or $coll)
                then
                  (
                    add_doc:handleAddition($dbName, $docPath),
                    script:success(("Le document '", $docId, "' a bien été mis à jour dans la base '", $dbName, "'.")) 
                  )
                 else script:error(concat("La collection '",  $coll, "' n'existe pas."))
        )
      else
        script:error(concat("Le document '", $docId, "' n'existe pas.")))
else
  script:error("Le fichier n'existe pas.")