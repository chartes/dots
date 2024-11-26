xquery version '3.0' ;

import module namespace dots.create = "backend/db_create";
import module namespace script = "script";

declare variable $dbName external; 
declare variable $projectDirPath external;

if ($dbName = "" or $projectDirPath = "") then (
  script:error("Renseigner les variables dbName (nom de la base de données) et / ou projectDirPath (chemin vers le dossier de dépôt.)")
) else if (not(file:exists($projectDirPath || "/data/"))) then (
  script:error("Les données TEI doivent être dans un dossier data/")
) else if (db:exists($dbName)) then (
  script:success(("La base de données '", $dbName, "' existe déjà et n'a pas été modifiée."))
) else (
  dots.create:db($dbName, $projectDirPath),
  script:success(("La base de donnée '", $dbName, "' a été créée."))
)
