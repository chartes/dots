xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_creator.xqm";

declare variable $dbName external; 
declare variable $projectDirPath external;

if ($dbName = "" or $projectDirPath = "")
then update:output("Erreur: Renseigner les variables dbName (nom de la base de données) et / ou projectDirPath (chemin vers le dossier de dépôt)
")
else
  if (db:exists($dbName))
  then
    update:output(concat("La base de donnée projet '", $dbName, "' existe déjà.
    "))
  else
    (dots.lib:dbCreate($dbName, $projectDirPath),
    update:output(concat("La base de donnée projet '", $dbName, "' a été créée.
    ")
))
