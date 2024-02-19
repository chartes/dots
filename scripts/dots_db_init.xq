xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_switch_builder.xqm";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

if (db:exists($G:dots))
then update:output("La base de données dots existe déjà. Commande non nécessaire.")
else
  (
    dots.lib:dots_db_init(),
    update:output("La base de données dots a été initialisée
")
  )