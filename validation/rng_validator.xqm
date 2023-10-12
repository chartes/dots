xquery version "3.1";

(:~  
: Ce module permet de vérifier la validité des registres DoTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-10-12
: @version  1.0
: @todo revoir et corriger les schémas
:)

module namespace valid = "https://github.com/chartes/dots/validation/rng_validator";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare function valid:handleValidations($dbName) {
  valid:dbSwitch(),
  valid:resourcesRegister($dbName),
  valid:fragmentsRegister($dbName)
};

declare function valid:dbSwitch() {
  let $dbSwitch := db:get($G:dots, $G:dbSwitcher)
  return
    validate:rng($dbSwitch, $G:dbSwitchValidation)
};


declare function valid:resourcesRegister($dbName) {
  let $doc := db:get($dbName, $G:resourcesRegister)
  return
    validate:rng($doc, $G:resourcesValidation)
};

declare function valid:fragmentsRegister($dbName) {
  let $doc := db:get($dbName, $G:fragmentsRegister)
  return
    validate:rng($doc, $G:fragmentsValidation)
};

