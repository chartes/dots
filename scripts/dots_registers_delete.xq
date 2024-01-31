xquery version "3.1";

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/dots_registers_delete.xqm";

declare variable $dbName external; 
declare variable $option external; 

dots.lib:handleDelete($dbName, "true"),
  if ($option = "true")
  then
    update:output(concat("La base de données ", $dbName, " a été supprimée et le switcher DoTS mis à jour
"))
  else
    update:output(concat("Les registres dots de la base de donnée ", $dbName, " ont été supprimés
"))