xquery version '3.0';

import module namespace dots.lib = "dots_switcher_update";
import module namespace dots.log = "log";
import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

declare variable $dbName external;

if ($dbName = "")
then ()
else
  if (db:exists($dbName))
  then
    if (db:get($dbName, $G:resourcesRegister))
    then
      if (db:get($G:dots)//member/project[@dbName = $dbName])
      then
        update:output("* ❌ Erreur : La liste des ressources est déjà présente dans le switcher dots et n'a pas été mis à jour.")
      else
        (
          dots.lib:switcher_update($dbName),
  update:output(concat("* ✅ La liste des ressources de la db '", $dbName, "' a été ajouté au switcher dots.
  ")),
          update:output(dots.log:log($dbName))
        )
