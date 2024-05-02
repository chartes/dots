xquery version "3.1";

module namespace dots.validation = "https://github.com/chartes/dots/validation/schema";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare updating function dots.validation:addSchema($dbName as xs:string) {
  let $mapping := (db:get($dbName, concat($G:metadata, "dots_metadata_mapping.xml")))
  let $frag := db:get($dbName)/tei:TEI//tei:citeStructure[1]
  return
    if ($mapping)
    then
      (
        db:add($dbName, $G:resourcesValidation, "dots/schema/resources_register.rng"),
        if ($frag)
        then
          db:add($dbName, $G:fragmentsValidation, "dots/schema/fragments_register.rng")
      ) 
    else ()
};