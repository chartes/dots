xquery version '3.0';

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/dots_switcher_update.xqm";
import module namespace dots.log = "https://github.com/chartes/dots/log" at "log.xq";

declare variable $dbName external;

if (db:exists($dbName))
then
  (
    dots.lib:switcher_update($dbName),
    update:output(concat("* ✅ La liste des ressources de la db '", $dbName, "' a été ajouté au switcher dots
")),
    update:output(dots.log:log($dbName))
  )
