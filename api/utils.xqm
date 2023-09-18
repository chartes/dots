xquery version "3.1";

(:~ 
: Ce module permet de construire les réponses à fournir pour les urls spécifiées dans routes.xqm. Il gère la communication entre 
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
: @todo pouvoir choisir l'identifiant de collection Route? (le title du endpoint collections sans paramètres)
: à déplacer dans globals.xqm?
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
              utils:getMandatory($member, "")
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
declare function utils:collectionById($id as xs:string, $nav as xs:string) {
  let $projectName := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $config := db:get($projectName, $G:configProject)//dots:member[@xml:id = $id]
  return
    <json type="object">{
      let $mandatory := utils:getMandatory($config, $nav)
      let $type := normalize-space($config/@type)
      let $dublincore := utils:getDublincore($config)
      let $extensions := utils:getExtensions($config)
      let $maxCiteDepth := normalize-space($config/@maxCiteDepth)
      let $members :=
        if ($type = "collection" or $nav = "parents")
        then
          for $member in 
            if ($nav = "parents")
            then
              let $idParent := substring-after($config/@target, "#")
              return db:get($projectName, $G:configProject)//dots:member[@xml:id= $idParent]
            else db:get($projectName, $G:configProject)//dots:member[@target = concat("#", $id)]
          let $mandatoryMember := utils:getMandatory($member, "")
          let $dublincoreMember := utils:getDublincore($member)
          let $extensionsMember := utils:getExtensions($member)
          return
            <item type="object">{
              $mandatoryMember,
              if ($extensionsMember/node()) then $extensionsMember else (),
              $dublincoreMember
            }</item>
        else ()
      let $response := 
        (
          $mandatory,
          if ($extensions/node()) then $extensions else (),
          $dublincore,
          if ($members) then <pair name="member" type="array">{$members}</pair>,
          if ($maxCiteDepth) then <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair> else ()
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
Fonctions d'entrée dans le endPoint "Navigation" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction permet de dispatcher vers les fonctions idoines en fonction des paramètres d'URL présents
: - utils:refNavigation si le paramètre $ref est présent,
: - utils:rangeNavigation si les paramètres $start et $end sont présents,
: - utils:idNavigation si seul le paramètre $id est disponible 
Chacune de ces fonctions permet de construire la réponse pour le endpoint Navigation de l'API DTS pour la resource identifiée par le paramètre $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $id chaîne de caractère permettant d'identifier la resource concernée. Ce paramètre vient de routes.xqm;routes.collections
: @param $ref chaîne de caractère permettant d'identifier un passage précis d'une resource. Ce paramètre vient de routes.xqm;routes.collections
: @param $start chaîne de caractère permettant de spécifier le début d'une séquence de passages d'une resource à renvoyer
: @param $end chaîne de caractère permettant de spécifier la fin d'une séquence de passages d'une resource à renvoyer
: @param $down châine de caractère indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:utils:refNavigation
: @see utils.xqm;utils:utils:rangeNavigation
: @see utils.xqm;utils:utils:idNavigation
: @todo revoir citeType
: @todo factoriser le code avec les 3 fonctions (utils:refNavigation(), utils:rangeNavigation())
:)
declare function utils:navigation($id as xs:string, $ref as xs:string, $start as xs:integer, $end as xs:integer, $down as xs:integer) {
  if ($ref)
  then utils:refNavigation($id, $ref, $down)
  else
    if ($start and $end)
    then utils:rangeNavigation($id, $start, $end, $down)
    else utils:idNavigation($id, $down)
      
};

(:~  
Cette fonction permet de construire la réponse d'API DTS pour le endpoint Navigation dans le cas où seul l'identifiant de la ressource est donnée.
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $id chaîne de caractère permettant d'identifier la resource concernée
: @param $down châine de caractère indiquant le niveau de profondeur des membres citables à renvoyer en réponse
:)
declare function utils:idNavigation($id as xs:string, $down) {
  let $projectName := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $resource := db:get($projectName, $G:configProject)//dots:member[@xml:id = $id]
  let $members :=
    for $member in db:get($projectName, $G:register)//dots:member[@target = concat("#", $id)]
    let $ref := normalize-space($member/@ref)
    let $level := normalize-space($member/@level)
    where if ($down) then xs:integer($level) = $down else xs:integer($level) = 1
    let $citeType := normalize-space($member/@citeType)
    let $dc := utils:getDublincore($member)
    let $extensions := utils:getExtensions($member)
    return
      <item type="object">
        <pair name="ref">{$ref}</pair>
        <pair name="level" type="number">{$level}</pair>
        {
          if ($citeType) then <pair name="citeType">{$citeType}</pair> else (),
          $dc,
          $extensions
        }
      </item>
  let $passage := <pair name="passage">{concat("/api/dts/document?id=", $id, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
  let $url := concat("/api/dts/navigation?id=", $id)
  let $maxCiteDepth := normalize-space($resource/@maxCiteDepth)
  return
    <json type="object">{
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>,
      <pair name="@id">{$url}</pair>,
      <pair name="level" type="number">0</pair>,
      if ($maxCiteDepth) then <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>,
      if ($members)
      then
        <pair name="member" type="array">{$members}</pair>
      else (),
        $passage,
      <pair name="parent" type="null"></pair>
    }</json>
};

(:~ 
: Cette fonction permet de construire la réponse pour le endpoint Navigation de l'API DTS pour le passage identifié par $ref de la resource $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $id chaîne de caractère permettant d'identifier la collection ou resource concernée. Ce paramètre vient de routes.xqm;routes.collections
: @param $ref chaîne de caractère permettant d'identifier un passage précis d'une resource. Ce paramètre vient de routes.xqm;routes.collections
: @param $down châine de caractère indiquant le niveau de profondeur des membres citables à renvoyer en réponse
:)
declare function utils:refNavigation($id as xs:string, $ref as xs:string, $down as xs:integer) {
  let $projectName := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $url := concat("/api/dts/navigation?id=", $id, "&amp;ref=", $ref)
  let $fragment := db:get($projectName, $G:register)//dots:member[@target = concat("#", $id)][@ref=$ref]
  let $level := normalize-space($fragment/@level)
  let $maxCiteDepth := normalize-space($fragment/@maxCiteDepth)
  let $citeType := normalize-space($fragment/@citeType)
  let $parent := normalize-space($fragment/@parent)
  let $members :=
    for $member in db:get($projectName, $G:register)//dots:member[@target = concat("#", $id)][@parent=$ref]
    let $ref := normalize-space($member/@ref)
    let $levelMember := normalize-space($member/@level)
    where if ($down) then xs:integer($levelMember) = $down + xs:integer($level) else xs:integer($levelMember) = xs:integer($level) + 1
    let $citeType := normalize-space($member/@citeType)
    let $dc := utils:getDublincore($member)
    let $extensions := utils:getExtensions($member)
    return
      <item type="object">
        <pair name="ref">{$ref}</pair>
        <pair name="level" type="number">{$levelMember}</pair>
        {
          if ($citeType) then <pair name="citeType">{$citeType}</pair> else (),
          $dc,
          $extensions
        }
      </item>
  return
    <json type="object">
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>
      <pair name="@id">{$url}</pair>
      <pair name="level" type="number">{$level}</pair>
      <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>
      {
        if ($citeType)
        then <pair name="citeType">{$citeType}</pair>,
        if ($members) then <pair name="member" type="array">{$members}</pair> else ()
      }
      <pair name="passage">{concat("/api/dts/document?id=", $id, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
      <pair name="parent" type="object">{
        if (substring-after($fragment/@target, "#") = $parent)
        then 
          (
           <pair name="@id">{$id}</pair>,
           <pair name="@type">resource</pair>
          )
        else 
          (
            <pair name="ref">{$parent}</pair>,
            <pair name="@type">CitableUnit</pair>
          )
      }</pair>
    </json>
};

(:~ 
: Cette fonction permet de construire la réponse pour le endpoint Navigation de l'API DTS pour la séquence de passages suivis entre $start et $end de la resource $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $id chaîne de caractère permettant d'identifier la collection ou resource concernée. Ce paramètre vient de routes.xqm;routes.collections
: @param $start chaîne de caractère permettant de spécifier le début d'une séquence de passages d'une resource à renvoyer
: @param $end chaîne de caractère permettant de spécifier la fin d'une séquence de passages d'une resource à renvoyer
: @param $down châine de caractère indiquant le niveau de profondeur des membres citables à renvoyer en réponse
:)
declare function utils:rangeNavigation($id as xs:string, $start as xs:integer, $end as xs:integer, $down as xs:integer) {
  let $projectName := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $url := concat("/api/dts/navigation?id=", $id, "&amp;start=", $start, "&amp;end=", $end, if ($down) then (concat("&amp;down=", $down)) else ())
  let $members :=
    for $range in $start to $end
    for $member in db:get($projectName, $G:register)//dots:member[@target = concat("#", $id)][starts-with(@ref, xs:string($range))][if ($down) then @level=$down else @level="1"]
    let $ref := normalize-space($member/@ref)
    let $level := normalize-space($member/@level)
    let $citeType := normalize-space($member/@citeType)
    return
      <item type="object">
        <pair name="ref">{$ref}</pair>
        <pair name="level">{$level}</pair>
        {if ($citeType) then <pair name="citeType">{$citeType}</pair>}
      </item>
  let $maxCiteDepth := normalize-space(db:get($projectName, $G:register)//dots:member[@target = concat("#", $id)][1]/@maxCiteDepth)
  return
    <json type="object">
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>
      <pair name="@id">{$url}</pair>
      <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>
      <pair name="level" type="number">1</pair>
      {if ($members) then <pair name="member" type="array">{$members}</pair> else ()}
      <pair name="passage">{concat("/api/dts/document?id=", $id, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
      <pair name="parent" type="null"></pair>
    </json>
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions d'entrée dans le endPoint "Document" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction donne accès au document ou à un fragment du document identifié par le paramètre $id
: @return document ou fragment de document XML
: @param $id chaîne de caractère permettant l'identification du document XML
: @param $ref chaîne de caractère indiquant un fragment à citer
: @param $start chaîne de caractère indiquant le début d'un passage cité
: @end $start chaîne de caractère indiquant la fin d'un passage cité
: @todo revoir la gestion de start et end!
:)
declare function utils:document($id as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string) {
  let $project := db:get($G:config)//dots:member[@xml:id = $id]/@projectPathName
  let $doc := db:get($project)/tei:TEI[@xml:id = $id]
  let $header := $doc/tei:teiHeader
  let $idRef := 
    if (db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $ref]/@xml:id)
    then db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $ref]/@xml:id
    else db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $ref]/@node-id
  let $ref := 
    if ($doc//node()[@xml:id = $idRef]) 
    then $doc//node()[@xml:id = $idRef]
    else db:get-id($project, $idRef)
  return
    if ($ref)
    then
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        {$header}
        <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{$ref}</dts:fragment>
      </TEI>
    else
      if ($start and $end)
      then
        let $sequence :=
          for $range in xs:integer($start) to xs:integer($end)
          let $idFragment := 
            if (db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $range]/@xml:id)
            then db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $range]/@xml:id
            else db:get($project, $G:register)//dots:member[@target = concat("#", $id)][@ref = $range]/@node-id
          let $fragment := 
            if ($doc//node()[@xml:id = $idFragment])
            then $doc//node()[@xml:id = $idFragment]
            else db:get-id($project, $idFragment)
          return
            $fragment
        return
          <TEI xmlns="http://www.tei-c.org/ns/1.0">
            {$header}
            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{$sequence}</dts:fragment>
          </TEI>
      else
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
: @todo envisager de modifier le paramètre $nav en $queryParams as map si plusieurs paramètres d'URI doivent être utilisés
:)
declare function utils:getMandatory($member as element(dots:member), $nav as xs:string) {
  let $id := normalize-space($member/@xml:id)
  let $type := normalize-space($member/@type)
  let $title := normalize-space($member/dc:title)
  let $totalParents := if ($member/@target) then 1 else 0
  let $totalItems := 
    if ($nav = "parents")
    then
      $totalParents
    else
      if ($member/@n) 
      then normalize-space($member/@n) 
      else 0
  let $passage := concat("/api/dts/document?id=", $id)
  let $references := concat("/api/dts/navigation?id=", $id)
  return
    (
      <pair name="@id">{$id}</pair>,
      <pair name="@type">{$type}</pair>,
      <pair name="title">{$title}</pair>,
      <pair name="totalItems" type="number">{$totalItems}</pair>,
      <pair name="totalChildren" type="number">{$totalItems}</pair>,
      <pair name="totalParents" type="number">{$totalParents}</pair>,
      <pair name="passage">{$passage}</pair>,
      <pair name="references">{$references}</pair>
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
  let $dc := $member/node()[starts-with(name(), "dc:")]
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
  let $extensions := $member/node()[not(starts-with(name(), "dc:"))][not(name() = "dc:title")]
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
    {if ($response = "")
    then ()
    else
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
