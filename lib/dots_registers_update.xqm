xquery version "3.1";

(:~  
: Ce module permet d'insérer un attribut @xml:id dans les fichiers TEI du projet sur tous les fragments XML qui n'en auraient pas. En complément, il remplace dans le registre DoTS des fragments la valeur des attributs @ref pour mettre en cohérence le contenu de cet attribut avec l'attribut @xml:id des fragments dans les sources TEI.
: @author École nationale des chartes - Philippe Pons
: @since 2024-10-29
: @version  1.0
: @todo revoir cette fonction si la valeur des attributs @ref est calculée (en s'apppuyant probablement sur la position du noeud dans le document)
:)

module namespace dots.update = "https://github.com/chartes/dots/lib";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare default element namespace "https://github.com/chartes/dots/";

declare updating function dots.update:updateFragments_register($dbName as xs:string) {
  for $fragments in db:get($dbName, $G:fragmentsRegister)//fragment
  let $node-id := $fragments/@node-id
  let $teiNode := db:get-id($dbName, $node-id)
  return
    if ($teiNode/@xml:id)
    then 
      dots.update:updateParentNodeRef($dbName, $fragments)
    else
      (
        dots.update:updateTEI_id($dbName, $fragments),
        dots.update:updateFragmentAttributs($dbName, $fragments)
      )
};

declare updating function dots.update:updateTEI_id($dbName, $fragment) {
  let $node-id := $fragment/@node-id
  let $teiNode := db:get-id($dbName, $node-id)
  let $newRefValue := concat("r", $node-id)
  return
    insert node attribute {"xml:id"} { $newRefValue } into $teiNode
};

declare updating function dots.update:updateFragmentAttributs($dbName, $fragment) {
  let $ref := $fragment/@ref
  let $newRefValue := concat("r", $ref)
  return
    (
      replace value of node $ref with $newRefValue,
      dots.update:updateParentNodeRef($dbName, $fragment)
    )
};

declare updating function dots.update:updateParentNodeRef($dbName as xs:string, $fragment as element(fragment)) {
  let $parentNodeId := $fragment/@parentNodeId
  let $parentNodeRef := $fragment/@parentNodeRef
  return
    if ($parentNodeId = $parentNodeRef)
    then
      replace value of node $parentNodeRef with concat("r", $parentNodeId)
    else ()
};

(:  
 for $frags in db:get($dbName, $G:fragmentsRegister)//fragment
  let $node-id := $frags/@node-id
  let $teiNode := db:get-id($dbName, $node-id)
  return
    if ($teiNode/@xml:id)
    then dots.update:changeParentNodeRefValue()
    else "function2"
  for $fragments in db:get($dbName, $G:fragmentsRegister)//fragment
  let $ref := $fragments/@ref
  let $node-id := $fragments/@node-id
  let $tei := db:get-id($dbName, $node-id)
  where not($tei/@xml:id)
  let $parentNodeId := $fragments/@parentNodeId
  let $refNewValue := concat("r", $node-id)
  return
    (
      replace value of node $ref with $refNewValue,
      insert node attribute {"xml:id"} { $refNewValue } into $tei,
      for $allFragments in db:get($dbName, $G:fragmentsRegister)//fragment
      let $parentNodeRef := $allFragments/@parentNodeRef
      let $parentNewNodeRef := 
        if (db:get-id($dbName, $allFragments/@parentNodeId)/@xml:id)
        then db:get-id($dbName, $allFragments/@parentNodeId)/@xml:id
        else concat("r", $parentNodeId)
      return
        replace value of node $parentNodeRef with $parentNewNodeRef
    )
:)

