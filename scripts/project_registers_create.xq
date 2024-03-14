xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/resources_register_builder.xqm";
import module namespace dots.log = "https://github.com/chartes/dots/log" at "log.xq";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare variable $dbName external;
declare variable $topCollectionId external;

dots.lib:createResourcesRegister($dbName, $topCollectionId),
if (db:get($dbName, $G:resourcesRegister) or db:get($dbName, $G:fragmentsRegister))
then
  (
    update:output(concat("Les registres dots pour la base de donnée ", $dbName, " ont été recréés.
")),
    update:output(dots.log:log($dbName)
  ))
else 
  (
    update:output(concat("Les registres dots pour la base de donnée ", $dbName, " ont été créés.
")),
    update:output(dots.log:log($dbName))
  )
