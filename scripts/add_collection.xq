xquery version '4.0' ;

import module namespace G = "globals";
import module namespace script = "script";
import module namespace add_coll = "backend/update/add_collection";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $resourceId external := ();
declare variable $parentId external := ();

let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $resourceId]
return
  if ($coll)
  then script:error(concat("La collection '", $resourceId, "' existe déjà."))
  else
    if ($parentId)
    then
      let $collParent := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $parentId]
      return
        if ($collParent != "")
        then
          (
            add_coll:handleAddition($dbName, $resourceId, $parentId),
            script:success(concat("La collection '", $resourceId, "', sous-collection de '", $parentId, "', a bien été ajouté à la db ", $dbName, "."))
          )
        else script:error(concat("La collection parente '", $parentId, "' n'existe pas."))
    else 
      (
        add_coll:handleAddition($dbName, $resourceId),
        script:success(concat("La collection '", $resourceId, "' a bien été ajouté à la db ", $dbName, "."))
      )
  
  


  