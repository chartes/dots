xquery version '3.0' ;

import module namespace resources = "backend/resources_register_builder";
import module namespace G = "globals";

declare variable $dbName external;
declare variable $topCollectionId external;

if ($dbName = "" or $topCollectionId ="")
then
  ()
else
  if (db:exists($dbName))
  then
    (
      if ($topCollectionId = "")
      then update:output("* ❌ Erreur : renseigner la variable topCollectionId (identifiant du projet)")
      else
        (
          resources:createResourcesRegister($dbName, $topCollectionId),
          if (db:get($dbName, $G:resourcesRegister) or db:get($dbName, $G:fragmentsRegister))
          then
            (
              update:output(concat("* ✅ Les registres dots pour la base de donnée '", $dbName, "' ont été recréés.
  "))
            )
          else 
            (
              update:output(concat("* ✅ Les registres dots pour la base de donnée '", $dbName, "' ont été créés.
  ")))
        )
    )