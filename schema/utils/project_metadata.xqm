xquery version "3.1";

(:~  
: Ce module permet de compléter un fichier de configuration d'un projet / d'une collection. Ce document sert ensuite pour le routeur dots. Spécifiquement, le rôle de ce module est de compléter le document de configuration, en intégrant dans les collections et ressources des métadonnées FACULTATIVES
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-25
: @version  1.0
:)

module namespace cc2 = "https://github.com/chartes/dots/schema/utils/cc2";

import module namespace G = "https://github.com/chartes/dots/globals" at "../../globals.xqm";
import module namespace cc = "https://github.com/chartes/dots/schema/utils/cc" at "project.xqm";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace html = "http://www.w3.org/1999/xhtml";

(:~
: Cette fonction permet de lancer les fonctions pour construire du contenu dans config: à partir d'un csv avec cc2:getCsvContent(), à partir des données TEI avec cc2:getTeiContent()
: @return le résultat des deux fonctions cc2:getCsvContent() et cc2:getTeiContent()
: @param $bdd chaîne de caractère qui correspond à un nom de db BaseX
: @param $id chaîne de caractère qui correspond à un identifiant @xml:id d'une ressource XML dans la db identifiée ci-dessus
: @see project_metadata.xqm;cc2:getCsvContent()
: @see project_metadata.xqm;cc2:getTeiContent()
:)
declare function cc2:getContent($bdd, $id) {
  cc2:getCsvContent($bdd, $id),
  cc2:getTeiContent($bdd, $id)
};

(:~  
: Cette fonction permet d'itérer sur chaque <member/> du fichier de configuration, et de retrouver la ligne CSV correspondante. Ensuite, en parcourant le document $G:declaration, il est possible d'ajouter le contenu CSV dans le <member/> du fichier de configuration.
: @return noeuds xml à insérer ou à mettre à jour dans le fichier de configuration
: @param $bdd chaîne de caractères qui correspond au nom d'une db BaseX
: @param $id chaîne de caractères qui correspond à l'identifiant @xml:id d'une ressource XML dans la db identifiée ci-dessus
: @see project_metadata.xqm;;cc2:createContent
: @todo en toute rigueur, $G:metadata devrait être complété ou remplacé (?) ici avec l'attribut @target du document declaration.xml.
: @todo /!\ Attention aux problèmes de namespace (notamment sur <csv/>)
:)
declare function cc2:getCsvContent($bdd as xs:string, $id as xs:string) {
  let $member := db:get($bdd, $G:configProject)//dots:member[@xml:id = $id]
  let $record := db:get($bdd, $G:metadata)/*:csv/*:record[*:id = $id]
  return
    if ($record)
    then
      for $itemDeclaration at $pos in db:get($bdd, $G:declaration)//dots:metadatas/node()[@format="csv"]
      let $key := $itemDeclaration/name()
      order by $key
      let $data := cc2:createContent($itemDeclaration, $record)
      return
        $data
    else ()
};

(:~  
: Cette fonction permet d'itérer sur chaque <member/> du fichier de configuration, et de retrouver la ressource TEI correspondante. Ensuite, en parcourant le document $G:declaration, il est possible d'ajouter du contenu présent dans le document TEI selon le XPath proposé dans $G:declaration.
: @return noeuds xml à insérer ou à mettre à jour dans le fichier de configuration
: @param $bdd chaîne de caractères qui correspond au nom d'une db BaseX
: @param $id chaîne de caractères qui correspond à l'identifiant @xml:id d'une ressource XML dans la db identifiée ci-dessus
:)
declare function cc2:getTeiContent($bdd as xs:string, $id as xs:string) {
  let $member := db:get($bdd, $G:configProject)//dots:member[@xml:id = $id]
  let $tei := db:open($bdd)/tei:TEI[@xml:id = $id]
  return
    if ($tei)
    then
      (
        for $itemDeclaration at $pos in db:get($bdd, $G:declaration)//dots:metadatas/node()[@xpath]
        where not(contains($itemDeclaration/@xpath, " "))
        let $dbPath := db:path(db:get($bdd)/tei:TEI[@xml:id= $id])
        let $key := $itemDeclaration/name()
        let $xpath1 := replace($itemDeclaration/@xpath, "/", "/*:")
        let $xpath2 := replace($xpath1, "*:@", "@")
        order by $key
        let $content := 
          for $item in xquery:eval($xpath1, map {"": db:get($bdd, $dbPath)})
          return
            normalize-space($item)
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
: @param $record élément XML <record/>
:)
declare function cc2:createContent($itemDeclaration, $record as element(record)) {
  let $key := $itemDeclaration/name()
  let $element := $itemDeclaration/@element
  let $value := 
    if ($record/node()[name() = $element] != "")
    then
      concat($itemDeclaration/@prefix, $record/node()[name() = $element], $itemDeclaration/@suffix)
    else ()
  let $subKey := $itemDeclaration/@key
  let $type := $itemDeclaration/@type
  return
    if ($value) 
    then 
      element {$key} {
        if ($type) then attribute { "type" } { $type } else (),
        if ($subKey) then attribute { "key" } { $subKey } else (),
        $value
      } 
    else 
      ()
};


