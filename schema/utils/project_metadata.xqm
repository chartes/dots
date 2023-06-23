xquery version "3.1";

(:~  
: Ce module permet de compléter un fichier de configuration d'un projet / d'une collection. Ce document sert ensuite pour le routeur dots. Spécifiquement, le rôle de ce module est de compléter le document de configuration, en intégrant dans les collections et ressources des métadonnées FACULTATIVES
: @author   Philippe Pons
: @since 2023-05-25
: @version  1.0
:)

module namespace cc2 = "https://github.com/chartes/dots/schema/utils/cc2";

import module namespace cc = "https://github.com/chartes/dots/schema/utils/cc" at "project.xqm";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare function cc2:getContent($bdd, $id) {
  cc2:getCsvContent($bdd, $id),
  cc2:getTeiContent($bdd, $id)
};

(:~  
: Cette fonction permet d'itérer sur chaque <member/> du fichier de configuration, et de retrouver la ligne CSV correspondante. Ensuite, en parcourant le document declaration.xml, il est possible d'ajouter le contenu CSV dans le <member/> du fichier de configuration.
: @return noeuds xml à insérer ou à mettre à jour dans le fichier de configuration
: @param $boolean booléen pour savoir si la fonction doit être utilisée ou non (à revoir?)
: @see complete_config.xql;cc2:createContent
:)
declare function cc2:getCsvContent($bdd as xs:string, $id as xs:string) {
  let $member := db:get($bdd, "config.xml")//dots:member[@xml:id = $id]
  let $record := db:open($bdd, "metadata")/csv/record[id = $id]
  return
    if ($record)
    then
      for $itemDeclaration at $pos in db:get($bdd, "declaration.xml")//dots:metadatas/node()[not(@xpath)]
      let $key := $itemDeclaration/name()
      order by $key
      let $data := cc2:createContent($itemDeclaration, $record)
      return
        $data
    else ()
};

declare function cc2:getTeiContent($bdd as xs:string, $id as xs:string) {
  let $member := db:get($bdd, "config.xml")//dots:member[@xml:id = $id]
  let $tei := db:open($bdd)/*:TEI[@xml:id = $id]
  return
    if ($tei)
    then
      (
        for $itemDeclaration at $pos in db:get($bdd, "declaration.xml")//dots:metadatas/node()[@xpath]
        where not(contains($itemDeclaration/@xpath, " "))
        let $dbPath := db:path(db:get($bdd)/tei:TEI[@xml:id= $id])
        let $key := $itemDeclaration/name()
        order by $key
        let $content := 
          for $item in xquery:eval(replace($itemDeclaration/@xpath, "/", "/*:"), map {"": db:get($bdd, $dbPath)})
          return
            $item
        let $data := 
          if ($content)
          then
            element {$key} {
              $content
            }
          else ()
        return
          $data
      )
    else ()
};

(:~  
: Cette fonction permet de construire le noeud XML à intégrer au fichier de configuration.
: @param $itemDeclaration noeud XML
: @param $record élément XML wrecord/>
:)
declare function cc2:createContent($itemDeclaration, $record as element(record)) {
  let $key := $itemDeclaration/name()
  let $element := $itemDeclaration/@element
  let $value := 
    if ($record/node()[name() = $element] != "")
    then
      concat($itemDeclaration/@prefix, $record/node()[name() = $element], $itemDeclaration/@suffix)
    else ()
  return
    if ($value != "") 
    then 
      if ($itemDeclaration/@type[. != "@id"])
      then
        element {$key} {
          attribute { "type" } { $itemDeclaration/@type },
          $value
        } 
    else 
      element {$key} {$value}
};


