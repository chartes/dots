xquery version "3.1";

(:~  
: Ce module permet d'insérer un attribut @xml:id dans les fichiers TEI du projet sur tous les fragments XML qui n'en auraient pas. En complément, il remplace dans le registre DoTS des fragments la valeur des attributs @ref pour mettre en cohérence le contenu de cet attribut avec l'attribut @xml:id des fragments dans les sources TEI.
: @author École nationale des chartes - Philippe Pons
: @since 2024-10-29
: @version  1.0
:)

module namespace dots.update = "backend/TEI_add_id";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";

declare updating function dots.update:addXmlIdToFragment($dbName as xs:string) {
  for $fragments in db:get($dbName, $G:fragmentsRegister)//fragment
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



