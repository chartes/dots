xquery version '3.0' ;

import module namespace dots.lib = "backend/create_custom_collections";
import module namespace script = "script";

declare variable $srcPath external;

if (file:exists($srcPath)) then (
  dots.lib:handle($srcPath),
  script:success("Les collections transverses ont été créées.")
) else (
  script:error("Problème de chemin.")
)
