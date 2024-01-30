xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/dots_switcher_update.xqm";

declare variable $dbName external;

dots.lib:switcher_update($dbName),
update:output(concat("La liste des ressources de la db ", $dbName, " a été ajouté au switcher dots
"))