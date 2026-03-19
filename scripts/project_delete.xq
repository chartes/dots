xquery version '3.0' ;

import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace script = "script";

declare variable $dbName external := ();
declare variable $option external := ();

if (not($dbName and $option)) then (
  script:error("La base de données n'existe pas.")
) else (
  dots.delete:handle($dbName, $option),
  if ($option = "true") 
  then script:success(concat("La base de données '", $dbName, "' a été supprimée et le switcher DoTS mis à jour"))
  else script:success(concat("Les registres dots de la base de donnée ", $dbName, " ont été supprimés")),
  if (db:get("dots")//*:project[@dbName = $dbName][@cacheOption = "true"])
  then 
    (
      store:delete($dbName),
      script:success(concat("Le cache de la db ", $dbName, " a été supprimé"))
    )
)
