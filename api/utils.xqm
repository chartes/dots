xquery version "3.1";

(:~ 
: Ce module permet de construire les réponses à fournir pour les urls spécifiées dans routes.xqm
: @author   École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
: @todo Revoir en profondeur les namespaces
:)

module namespace utils = "https://github.com/chartes/dots/api/utils";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace routes = "https://github.com/chartes/dots/api/routes" at "routes.xqm";
import module namespace functx = 'http://www.functx.com';

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~  
: Cette variable permet de choisir l'identifiant d'une collection "racine" (pour le endpoint Collections sans paramètre d'identifiant)
:)
declare variable $utils:root := "ELEC";

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions d'entrée dans le endPoint "Collections" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction permet de lister les collections DTS dépendant d'une collection racine $utils:root.
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:getContex
:)
declare function utils:collections() {
  let $totalItems := xs:integer(db:get($G:config)//dots:projects/@n)
  let $content :=
    (
      <pair name="@id">{$utils:root}</pair>,
      <pair name="@type">collection</pair>,
      <pair name="title">{string("Éditions numériques de l'école nationale des chartes")}</pair>,
      <pair name="totalItems" type="number">{$totalItems}</pair>,
      <pair name="member" type="object">{
        for $project at $pos in db:get($G:config)//dots:member[not(@target)]
        let $id := normalize-space($project/@xml:id)
        let $projectName := $project/@projectPathName
        let $dbPrjt := db:get($projectName, $G:configProject)
        let $member := $dbPrjt//dots:member[@xml:id = $id]
        return
          if ($member) 
          then 
            <pair name="{$pos}" type="object">{
              utils:getMandatory($member)
            }</pair> 
          else ()
      }</pair>
    )
  let $context := utils:getContext($content)
  return
    <json type="object">{
      $content,
      $context
    }</json>
};

(:~ 
: Cette fonction permet de construire la réponse d'API d'une collection DTS identifiée par le paramètre $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $id chaîne de caractère permettant d'identifier la collection ou resource concernée. Ce paramètre vient de routes.xqm;routes:collections
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:getMandatory
: @see utils.xqm;utils:getDublincore
: @see utils.xqm;utils:getExtensions
: @see utils.xqm;utils:getContext
:)
declare function utils:collectionById($id as xs:string) {
  <json type="object">{
    let $projectName := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
    let $config := db:get($projectName, $G:configProject)//dots:member[@xml:id = $id]
    let $mandatory := utils:getMandatory($config)
    let $type := normalize-space($config/@type)
    let $dublincore := utils:getDublincore($config)
    let $extensions := utils:getExtensions($config)
    let $members :=
      if ($type = "collection")
      then
        <pair name="member" type="array">{
          for $member in db:get($projectName, $G:configProject)//dots:member[@target = concat("#", $id)]
          let $mandatoryMember := utils:getMandatory($member)
          let $dublincoreMember := utils:getDublincore($member)
          let $extensionsMember := utils:getExtensions($member)
          return
            (
              <item type="object">{
                $mandatoryMember,
                if ($extensionsMember/node()) then $extensionsMember else (),
                $dublincoreMember
              }</item>
            )
        }</pair>
      else ()
    let $response := 
      (
        $mandatory,
        if ($extensions/node()) then $extensions else (),
        $dublincore,
        $members
      )
    let $context := utils:getContext($response)
    return
      (
        $response,
        $context
      )
  }</json>
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions d'entrée dans le endPoint "Document" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction donne accès au document ou à un fragment du document identifié par le paramètre $id
: @return document ou fragment de document XML
: @param $id chaîne de caractère permettant l'identification du document XML
: @todo prévoir l'ajout de nouveaux paramètres pour accéder à un fragment de document: @ref, @start, @end...
:)
declare function utils:document($id as xs:string) {
  let $project := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $doc := db:get($project)/tei:TEI[@xml:id = $id]
  return
    $doc
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions "utiles"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction permet de préparer les données obligatoires à servir pour le endpoint Collection de l'API DTS: @id, @type, @title, @totalItems (à compléter probablement)
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $member élément XML <member/> où se trouvent toutes les informations à servir en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collections (fonction qui fait appel à la fonction ici présente)
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
:)
declare function utils:getMandatory($member as element(dots:member)) {
  let $id := normalize-space($member/@xml:id)
  let $type := normalize-space($member/@type)
  let $title := normalize-space($member/dc:title)
  let $totalItems := if ($member/@n) then normalize-space($member/@n) else 0
  return
    (
      <pair name="@id">{$id}</pair>,
      <pair name="@type">{$type}</pair>,
      <pair name="title">{$title}</pair>,
      <pair name="totalItems" type="number">{$totalItems}</pair>
    )
};

(:~ 
: Cette fonction permet de préparer les données en Dublincore pour décrire une collection ou une resource
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $member élément XML <member/> où se trouvent toutes les informations à servir en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
:)
declare function utils:getDublincore($member as element(dots:member)) {
  let $dc := $member/node()[starts-with(name(), "dct:")]
  return
    if ($dc)
    then
      <pair name="dts:dublincore" type="object">{
        for $metadata in $dc
        let $key := $metadata/name()
        let $countKey := count($dc/name()[. = $key])
        group by $key
        order by $key
        return
          if ($countKey > 1)
          then
            utils:getArrayJson($key, $metadata)
          else
            if ($key)
            then utils:getStringJson($key, $metadata)
            else ()
      }</pair>
    else ()
};

(:~ 
: Cette fonction permet de préparer toutes les données non Dublincore utilisées pour décrire une collection ou une resource
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $member élément XML <member/> où se trouvent toutes les informations à servir en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
:)
declare function utils:getExtensions($member as element(dots:member)) {
  let $extensions := $member/node()[not(starts-with(name(), "dct:"))][not(name() = "dc:title")]
  return
    if ($extensions)
    then
      <pair name="dts:extensions" type="object">{
        for $metadata in $extensions
        let $key := $metadata/name()
        where $key != ""
        let $countKey := count($extensions/name()[. = $key])
        group by $key
        order by $key
        return
          if ($countKey > 1)
          then
            utils:getArrayJson($key, $metadata)
          else
            if ($countKey = 0)
            then ()
            else
             utils:getStringJson($key, $metadata)
      }</pair>
    else ()
};


(:~ 
: Cette fonction permet de construire un tableau XML de métadonnées
: @return élément XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $key chaîne de caractères qui servira de clef JSON
: @param $metada élément XML
:)
declare function utils:getArrayJson($key as xs:string, $metadata) {
  <pair name="{$key}" type="array">{
    for $meta in $metadata
    return
      <item>{
        if ($meta/@key) 
        then (
          attribute {"type"} {"object"},
          utils:getStringJson($meta/@key, $meta)
        )
        else 
          (
            if ($meta/@type)
            then
              (
                attribute {"type"} {$meta/@type},
                normalize-space($meta)
              )
            else 
              normalize-space($meta)
          )
      }</item>
  }</pair>
};

(:~ 
: Cette fonction permet de construire un élément XML
: @return élément XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $key chaîne de caractères qui servira de clef JSON
: @param $metada élément XML
:)
declare function utils:getStringJson($key as xs:string, $metadata) {
  <pair name="{$key}">{
    if ($metadata/@type) then attribute {"type"} {$metadata/@type} else (),
    normalize-space($metadata)
  }</pair>
};

(:~  
: Cette fonction permet de donner la liste des vocabulaires présents dans la réponse à la requête d'API
: @return réponse XML, pour être ensuite sérialisées en JSON (format: attributes)
: @param $response séquence XML pour trouver les namespaces présents (si nécessaire)
:)
declare function utils:getContext($response) {
  <pair name="@context" type="object">
    <pair name="dts">https://w3id.org/dts/api#</pair>
    <pair name="vocab">https://www.w3.org/ns/hydra/core#</pair>
    {
      for $name in $response//@name
      where contains($name, ":")
      let $namespace := substring-before($name, ":")
      group by $namespace
      return
        switch ($namespace)
        case ($namespace[. = "dc"]) return <pair name="dc">{"http://purl.org/dc/elements/1.1/"}</pair>
        case ($namespace[. = "dct"]) return <pair name="dct">{"http://purl.org/dc/terms/"}</pair>
        case ($namespace[. = "html"]) return <pair name="html">{"http://www.w3.org/1999/xhtml"}</pair>
        default return ()
  }</pair>
};
