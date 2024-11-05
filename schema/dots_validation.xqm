xquery version "3.1";

(:  
: 1. copier / coller les schémas dots (resources et fragments si nécessaires)
: 2. update le(s) schémas dots de la db
: 3. lancer la validation des modules
:)

module namespace dots.validation = "https://github.com/chartes/dots/validation";

declare default element namespace "https://github.com/chartes/dots/";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare updating function dots.validation:resourcesSchema($dbName) {
  let $mapping := (db:get($dbName, concat($G:metadata, "dots_metadata_mapping.xml")))
  return
    if ($mapping)
    then 
      let $collectionNodes :=
        for $node in $mapping//mapping/node()[@scope = "collection"]
        let $nodeName := $node/name()
        group by $nodeName
        return
          $nodeName
      let $documentNodes :=
        for $node in $mapping//mapping/node()[@scope = "document"]
        let $nodeName := $node/name()
        group by $nodeName
        return
          $nodeName
      return 
        (
          dots.validation:collectionElement($dbName, $collectionNodes),
          dots.validation:documentElement($dbName, $documentNodes)
        )
};

declare updating function dots.validation:collectionElement($dbName as xs:string, $sequence) {
  let $define := db:get($dbName, "/dots/schema/resources_register.rng")//*:define[@name = "collection"]/*:element
  for $node in $sequence
  let $element :=
    <element xmlns="http://relaxng.org/ns/structure/1.0" name="{$node}">
      <data type="unsignedLong"/>
    </element>
  return
    insert node $element as last into $define/*:optional 
};

declare updating function dots.validation:documentElement($dbName as xs:string, $sequence) {
  let $define := db:get($dbName, "/dots/schema/resources_register.rng")//*:define[@name = "document"]/*:element
  return
    insert node 
      <optional xmlns="http://relaxng.org/ns/structure/1.0">{
        for $node in $sequence
        let $element :=
          <element name="{$node}">
            <data type="unsignedLong"/>
          </element>
        return
          $element
      }</optional> as last into $define 
};

