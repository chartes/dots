xquery version "3.1";

import module namespace dots.delete = "backend/dots_registers_delete";
import module namespace script = "script";

declare variable $dbName external; 
declare variable $option external; 

if ($dbName = "")
then ()
else (
  dots.delete:handle($dbName, $option),
  if ($option = "true") then (
    script:success(("La base de données '", $dbName, "' a été supprimée et le switcher DoTS mis à jour"))
  ) else (
    script:success(("Les registres dots de la base de donnée ", $dbName, " ont été supprimés"))
  )
)