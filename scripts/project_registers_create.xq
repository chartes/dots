xquery version '3.0' ;

import module namespace resources = "backend/resources_register_builder";
import module namespace G = "globals";
import module namespace script = "script";

declare variable $dbName external := ();
declare variable $topCollectionId external := ();

if ($dbName and db:exists($dbName)) then (
  if (not($topCollectionId)) then (
    script:error("Renseigner la variable topCollectionId (identifiant du projet)")
  ) else (
    resources:createResourcesRegister($dbName, $topCollectionId),
    if (db:get($dbName, $G:resourcesRegister) or db:get($dbName, $G:fragmentsRegister)) then (
      script:success(("Les registres dots pour la base de donnée '", $dbName, "' ont été recréés."))
    ) else (
      script:success(("Les registres dots pour la base de donnée '", $dbName, "' ont été créés."))
    )
  )
)