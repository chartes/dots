xquery version '3.0' ;

import module namespace dots.lib = "backend/db_switch_builder";
import module namespace G = "globals";

if (db:exists($G:dots))
then update:output("* ✅ La base de données 'dots' existe déjà. Commande non nécessaire.
")
else
  (
    dots.lib:dots_db_init(),
    update:output("* ✅ La base de données 'dots' a été initialisée.
")
  )