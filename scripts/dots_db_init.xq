xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_switch_builder.xqm";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

if (db:get($G:dots))
then 
  update:output("La base de donnée dots existe déjà.
")
else
  (
    dots.lib:dots_db_init(),
    update:output("La base de donnée dots a été initialisée.
")    
  )
