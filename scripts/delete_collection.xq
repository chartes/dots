xquery version '4.0' ;

import module namespace G = "globals";
import module namespace script = "script";
import module namespace del_coll = "backend/update/delete_collection";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external := ();
declare variable $resourceId external := ();
declare variable $option external := false();

let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $resourceId]
return
  if ($coll)
  then 
    (
      del_coll:handleDeleteColl($dbName, $resourceId, $option),
      script:success(concat("La collection '", $resourceId, "' a bien été supprimée de la base '", $dbName, "'.")),
      del_coll:handleDocInColl($dbName, $resourceId, $option),
      if ($option) then script:success(concat("Le(s) documents de la collection '", $resourceId, "' ont bien été supprimés."))
    )
  else script:error(concat("La collection '", $resourceId, "' n'existe pas."))
  
  


  