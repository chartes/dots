xquery version "4.0";

(:~
: This module ensures that all TEI fragments in a given project have an `@xml:id` attribute.
: For each fragment that lacks an `@xml:id`, the module inserts a new one based on its internal `@node-id`.
: Additionally, it updates the corresponding entry in the DoTS fragment register by replacing the `@ref` attribute
: to ensure consistency between the TEI source and the register.
: @author  École nationale des chartes – Philippe Pons
: @since   2024-10-29
: @version 1.0
:)

module namespace dots.update = "backend/TEI_add_id";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

(:~
: This function adds missing `@xml:id` attributes to TEI fragments and synchronizes references in the DoTS fragment register.
: For each `<fragment>` listed in the project's register, this function checks whether the corresponding TEI element
: (retrieved by `@node-id`) is missing an `@xml:id`. If so, it inserts a new ID generated from the `node-id`,
: and updates the `@ref` attribute of the `<fragment>` element in the register accordingly.
: @param $dbName  the name of the project database.
: @return         a sequence of update operations inserting `@xml:id` attributes and replacing `@ref` values.
:)
declare updating function dots.update:addXmlIdToFragment($dbName as xs:string) {
  let $fragmentsRegister := if (db:get($dbName, $G:fragmentsRegister)) then db:get($dbName, $G:fragmentsRegister) else db:get($dbName, concat("/", $G:fragmentsRegister))
  for $fragments in $fragmentsRegister//fragment
  let $node-id := $fragments/@node-id
  let $tei := db:get-id($dbName, $node-id)
  where not($tei/@xml:id)
  let $ref := $fragments/@ref
  let $refValue := concat("r", $node-id)
  return
    (
      insert node attribute {"xml:id"} { $refValue } into $tei,
      replace value of node $ref with $refValue 
    )
};



