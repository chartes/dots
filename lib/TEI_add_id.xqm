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

declare updating function dots.update:addXmlIdToFragment($dbName as xs:string) {
  for $fragments in db:get($dbName, $G:fragmentsRegister)//fragment
  let $ref := $fragments/@ref
  let $node-id := $fragments/@node-id
  let $tei := db:get-id($dbName, $node-id)
  where not($tei/@xml:id)
  let $refValue := concat("r", $node-id)
  return
    (
      replace value of node $ref with $refValue,
      insert node attribute {"xml:id"} { $refValue } into $tei
    )
};



