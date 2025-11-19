xquery version '4.0' ;

import module namespace G = "globals";
import module namespace script = "script";
import module namespace del_coll = "backend/update/delete_collection";

declare namespace dots = "https://github.com/chartes/dots/";

declare variable $dbName external;
declare variable $resourceId external;
declare variable $projectDirPath external;
declare variable $option external := false;

let $coll := db:get($dbName, $G:resourcesRegister)//dots:collection[@dtsResourceId = $resourceId]
return
  if ($coll)
  then 
    if (db:get($G:dots)//dots:project[@dtsResourceId = $resourceId])
    then
      script:error(concat("Pour supprimer le projet DoTS '", $resourceId, "', utiliser le script `scripts/project_delete.sh`"))
    else
      (
        del_coll:handleDeleteColl($dbName, $resourceId, $projectDirPath, $option),
        script:success(concat("La collection '", $resourceId, "' a bien été supprimée de la base '", $dbName, "'.")),
        del_coll:handleDocInColl($dbName, $resourceId, $option),
        if ($option) then script:success(concat("Le(s) document(s) de la collection '", $resourceId, "' ont bien été supprimés."))
      )
  else script:error(concat("La collection '", $resourceId, "' n'existe pas."))
  



  