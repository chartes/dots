xquery version "3.1";

(:~  
: Ce module permet de créer un fichier de configuration général. Ce document sert ensuite pour le routeur DoTS. Spécifiquement, le rôle de ce module est de créer le document de configuration général, en intégrant toutes les collections existantes et leurs membres avec le lien vers le projet correspondant.
: @author École nationale des chartes - Philippe Pons
: @since 2023-06-14
: @version  1.0
:)

module namespace ccg = "https://github.com/chartes/dots/schema/utils/ccg";

import module namespace G = "https://github.com/chartes/dots/globals" at "../../globals.xqm";
import module namespace cc = "https://github.com/chartes/dots/schema/utils/cc" at "project.xqm";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare updating function ccg:create_config($idBdd) {
  if (db:exists($G:config))
  then 
    let $config := db:get($G:config)
    let $lastUpdate := $config//dots:lastUpdate
    let $projects := $config//dots:projects
    let $members := ccg:members($idBdd, "")
    return
      (
        replace value of node $lastUpdate with current-dateTime(),
        if ($projects/dots:member/@xml:id = $idBdd)
        then ()
        else
          (
            replace value of node $projects/@n with xs:integer($projects/@n) + 1,
            insert node ccg:getProject($idBdd) as last into $projects
          ),
        for $member in $members
        let $id := $member/@xml:id
        return
          if ($config//dots:members/dots:member[@xml:id = $id])
          then replace node $config//dots:members/dots:member[@xml:id = $id] with $member
          else 
            insert node $member as last into $config//dots:members
      )
  else
    let $content :=
      <dots:configuration xmlns:dct="http://purl.org/dc/terms/" xmlns:dots="https://github.com/chartes/dots/" xmlns:dc="http://purl.org/dc/elements/1.1/">
        {ccg:getMetadata()},
        <dots:configContent>
          <dots:projects n="1">{
            ccg:getProject($idBdd)
          }</dots:projects>
          <dots:members>{
            ccg:members($idBdd, "")
          }</dots:members>
        </dots:configContent>
      </dots:configuration>
    return
      db:create($G:config, $content, $G:configProject)
};

(:~ 
: Cette fonction se contente de construire l'en-tête <dots:configMetadata/> du fichier de configuration
:)
declare function ccg:getMetadata() {
  <dots:configMetadata>
    <dots:gitVersion/><!-- version git du fichier -->
    <dots:creationDate>{current-dateTime()}</dots:creationDate><!-- date de création du document -->
    <dots:lastUpdate>{current-dateTime()}</dots:lastUpdate><!-- date de la dernière mise à jour -->
    <dots:publisher>École nationale des chartes</dots:publisher>
    <dots:description>Bibliothèque de resources DTS</dots:description>
    <dots:licence>https://opensource.org/license/mit/</dots:licence>
  </dots:configMetadata>
};

declare function ccg:getProject($idBdd) {
  <dots:member xml:id="{$idBdd}" type="collection" projectPathName="{$idBdd}"/>
};

declare function ccg:members($idBdd as xs:string, $path as xs:string) {
  for $dir in db:dir($idBdd, $path)
  where not(contains($dir, $G:metadata))
  order by $dir
  return
    if (contains($dir, ".xml"))
    then ccg:resource($idBdd, $dir, $path)
    else
      (
        ccg:collection($idBdd, $dir, $path), 
        ccg:members($idBdd, $dir)
      )
};

declare function ccg:resource($idBdd as xs:string, $resource as xs:string, $path as xs:string) {
  let $doc := db:get($idBdd, concat($path, "/", $resource))/tei:TEI
  let $id := normalize-space($doc/@xml:id)
  let $title := normalize-space($doc//tei:titleStmt/tei:title[1])
  return
    if ($doc)
    then
      <dots:member xml:id="{$id}" target="#{if ($path) then $path else $idBdd}" type="resource" projectPathName="{$idBdd}"/>
    else ()
};

declare function ccg:collection($idBdd as xs:string, $collection as xs:string, $path as xs:string) {
  let $totalItems := count(db:dir($idBdd, $collection))
  let $parent := if ($path = "") then $idBdd else $path
  let $title := db:open($idBdd, $G:declaration)//dots:titles/dots:title[@xml:id=$collection]
  return
    <dots:member xml:id="{$collection}" target="#{$parent}" type="collection" projectPathName="{$idBdd}"/>
};







