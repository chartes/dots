xquery version "4.0";

(:~  
: This module adds a `@xml:id` attribute to TEI fragments that lack one.
: It also ensures consistency between TEI sources and the DoTS fragment register,
: by updating the `@ref` attributes in the register so they match the corresponding `@xml:id` values.
: @author École nationale des chartes - Philippe Pons
: @since 2024-10-29
: @version  1.0
:)

module namespace dots.update = "backend/dots_registers_update";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

(:~ 
: Updates all `<fragment>` elements in the DoTS register of the given database.
: For each fragment, checks whether the corresponding TEI node has an `@xml:id`.
: - If it already exists, only the parent node reference is updated.
: - If not, an `@xml:id` is inserted into the TEI node, and the corresponding `@ref`
:   value in the register is updated to maintain consistency.
: @param $dbName the name of the BaseX database to update
: @return performs update operations in the TEI files and in the fragments register.
:)
declare updating function dots.update:updateFragments_register($dbName as xs:string) {
  for $fragments in db:get($dbName, $G:fragmentsRegister)//fragment
  let $node-id := $fragments/@node-id
  let $teiNode := db:get-id($dbName, $node-id)
  return 
    if ($teiNode/@xml:id) then (
      dots.update:updateParentNodeRef($dbName, $fragments)
    ) 
    else (
      dots.update:updateTEI_id($dbName, $fragments),
      dots.update:updateFragmentAttributs($dbName, $fragments)
  )
};

(:~
: Inserts a new `@xml:id` attribute into a TEI fragment node.
: The value is generated using the `node-id`, prefixed with "r".
: @param $dbName the name of the BaseX database
: @param $fragment the `<fragment>` element in the DoTS register
: @return insert an attribute `@xml:id` to a TEI element.
:)
declare updating function dots.update:updateTEI_id($dbName, $fragment) {
  let $node-id := $fragment/@node-id
  let $teiNode := db:get-id($dbName, $node-id)
  let $newRefValue := concat("r", $node-id)
  return 
    insert node attribute {"xml:id"} { $newRefValue } into $teiNode
};

(:~
: Updates the `@ref` attribute of a `<fragment>` element in the DoTS register
: to match the `@xml:id` convention. Also calls `updateParentNodeRef` to update
: parent reference if needed.
: @param $dbName the name of the BaseX database
: @param $fragment the `<fragment>` element to update
: @return a sequence of update operations: the new `@ref` value and the parent reference update
:)
declare updating function dots.update:updateFragmentAttributs($dbName, $fragment) {
  let $ref := $fragment/@ref
  let $newRefValue := concat("r", $ref)
  return (
    replace value of node $ref with $newRefValue,
    dots.update:updateParentNodeRef($dbName, $fragment)
  )
};

(:~
: Ensures that the `@parentNodeRef` attribute of a `<fragment>` in the DoTS register
: uses the same `r`-prefixed convention as other `@ref` attributes.
: Only performs the update if the `@parentNodeRef` is equal to the raw `@parentNodeId`.
: @param $dbName the name of the BaseX database
: @param $fragment the `<fragment>` element to update
: @return an update operation if the `@parentNodeRef` is updated; otherwise, an empty sequence
:)
declare updating function dots.update:updateParentNodeRef($dbName as xs:string, $fragment as element(fragment)) {
  let $parentNodeId := $fragment/@parentNodeId
  let $parentNodeRef := $fragment/@parentNodeRef
  where $parentNodeId = $parentNodeRef
  return replace value of node $parentNodeRef with concat("r", $parentNodeId)
};
