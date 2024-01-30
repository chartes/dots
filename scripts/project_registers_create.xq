xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/resources_register_builder.xqm";

declare variable $dbName external;
declare variable $topCollectionId external;

dots.lib:create_config($dbName, $topCollectionId),
update:output(concat("Les registres dots pour la base de donnée ", $dbName, " ont été créés
"))

