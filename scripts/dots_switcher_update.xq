xquery version '3.0';

import module namespace dots.update = "backend/dots_switcher_update";
import module namespace dots.report = "report";
import module namespace G = "globals";
import module namespace script = "script";

declare default element namespace "https://github.com/chartes/dots/";

declare variable $dbName external := ();

if ($dbName and db:exists($dbName) and db:get($dbName, $G:resourcesRegister)) then (
  if (db:get($G:dots)//member/project[@dbName = $dbName]) then (
    script:error("La liste des ressources est déjà présente dans le switcher dots et n'a pas été mis à jour.")
  ) else (
    dots.update:switcher($dbName),
    script:success(("La liste des ressources de la db '", $dbName, "' a été ajouté au switcher dots.")),
    update:output(dots.report:log($dbName))
  )
)
