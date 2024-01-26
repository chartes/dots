xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_creator.xqm";

declare variable $dbName external; 
declare variable $projectDirPath external;

dots.lib:dbCreate($dbName, $projectDirPath),
update:output(concat("La base de donnée projet: ", $dbName, " a été créée
")
)
