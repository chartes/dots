xquery version '3.0' ;

import module namespace dots.build = "backend/db_switch_build";
import module namespace G = "globals";
import module namespace script = "script";

declare variable $rootId external := ();
declare variable $rootTitle external := ();
declare variable $rootDescription external := ();

if (db:exists($G:dots)) then (
  script:success("La base de données 'dots' existe déjà. Commande non nécessaire.")
) else (
  dots.build:dots_db($rootId, $rootTitle, $rootDescription),
  script:success("La base de données 'dots' a été initialisée.")
)