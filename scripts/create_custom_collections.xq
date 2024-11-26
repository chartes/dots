xquery version '3.0' ;

import module namespace dots.lib = "backend/create_custom_collections";

declare variable $srcPath external;

if (file:exists($srcPath))
then
  (
    dots.lib:handle($srcPath),
    update:output("* ✅ les collections transverses ont été créées.")
  )
else
  update:output("* ❌ Erreur : problème de chemin.")