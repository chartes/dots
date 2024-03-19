xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_creator.xqm";

declare variable $dbName external; 
declare variable $projectDirPath external;

if ($dbName = "" or $projectDirPath = "")
then update:output("* ❌ Erreur: Renseigner les variables dbName (nom de la base de données) et / ou projectDirPath (chemin vers le dossier de dépôt.)
")
else
  if (not(file:exists(concat($projectDirPath, "/data/"))))
  then update:output("* ❌ Erreur: les données TEI doivent être dans un dossier data/
")
  else
    if (db:exists($dbName))
    then update:output(concat("* ✅ La base de données '", $dbName, "' existe déjà.
"))
    else
      (dots.lib:dbCreate($dbName, $projectDirPath),
      update:output(concat("* ✅ La base de donnée '", $dbName, "' a été créée.
")
    ))
