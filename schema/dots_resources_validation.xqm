xquery version "3.1";

module namespace dots.valide = "https://github.com/chartes/dots/validation/validate";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare function dots.valide:resourcesValidation($dbName) {
  let $schema := db:get($dbName, "dots/schema/resources_register.rng")
  let $doc := db:get($dbName, $G:resourcesRegister)
  return
    validate:rng-info($doc, $schema)
};