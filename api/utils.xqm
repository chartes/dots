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
  let $totalItems := xs:integer(db:get($G:dots)/dots:dbSwitch/dots:metadata/dots:totalProjects)
  let $content :=
    (
      <pair name="@id">{$utils:root}</pair>,
      <pair name="@type">collection</pair>,
      <pair name="title">{string("Éditions numériques de l'école nationale des chartes")}</pair>,
      <pair name="totalItems" type="number">{$totalItems}</pair>,
      <pair name="member" type="object">{
        for $project at $pos in db:get($G:dots)//dots:member/dots:project
        let $resourceId := normalize-space($project/@dtsResourceId)
        let $dbName := $project/@dbName
        let $resourcesRegister := db:get($dbName, $G:resourcesRegister)
        let $resource := $resourcesRegister//dots:member/node()[@dtsResourceId = $resourceId]
        return
          if ($resource) 
          then 
            <pair name="{$pos}" type="object">{
              utils:getMandatory($resource, "")
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
declare function utils:collectionById($resourceId as xs:string, $nav as xs:string) {
  let $projectName := utils:getDbName($resourceId)
  let $resource := utils:getResource($projectName, $resourceId)
  return
    <json type="object">{
      let $mandatory := utils:getMandatory($resource, $nav)
      let $type := utils:getResourceType($resource)
      let $dublincore := utils:getDublincore($resource)
      let $extensions := utils:getExtensions($resource)
      let $maxCiteDepth := normalize-space($resource/@maxCiteDepth)
      let $members :=
        if ($type = "collection" or $nav = "parents")
        then
          for $member in 
            if ($nav = "parents")
            then
              let $idParent := normalize-space($resource/@parentIds)
              return utils:getResource($projectName, $idParent) 
            else utils:getChildMembers($projectName, $resourceId) 
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
declare function utils:navigation($id as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $down as xs:integer) {
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
declare function utils:idNavigation($resourceId as xs:string, $down) {
  let $projectName := utils:getDbName($resourceId) 
  let $resource := utils:getResource($projectName, $resourceId)
  let $members :=
    for $fragment in utils:getFragment($projectName, $resourceId, map {"id": $resourceId})
    let $ref := normalize-space($fragment/@ref)
    let $level := xs:integer($fragment/@level)
    where if ($down) then xs:integer($level) = $down else xs:integer($level) = 1
    let $citeType := normalize-unicode($fragment/@citeType)
    let $dc := utils:getDublincore($fragment)
    let $extensions := utils:getExtensions($fragment)
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
  let $passage := <pair name="passage">{concat("/api/dts/document?id=", $resourceId, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
  let $url := concat("/api/dts/navigation?id=", $resourceId)
  let $maxCiteDepth := if ($resource/@maxCiteDepth) then xs:integer($resource/@maxCiteDepth) else ()
  return
    <json type="object">{
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>,
      <pair name="@id">{$url}</pair>,
      <pair name="level" type="number">0</pair>,
      <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>,
      if ($members)
      then
        <pair name="member" type="array">{$members}</pair> else (),
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
: @todo revoir le listing des members dans les cas où maxCiteDepth > 1
: @todo revoir bug sur dts:extensions qui apparaît même si rien
: @todo revoir <pair name="parent"></pair> => ajouter un attribut @parentResource sur les fragments
:)
declare function utils:refNavigation($resourceId as xs:string, $ref as xs:string, $down as xs:integer) {
  let $projectName := utils:getDbName($resourceId)
  let $url := concat("/api/dts/navigation?id=", $resourceId, "&amp;ref=", $ref)
  let $fragment :=  utils:getFragment($projectName, $resourceId, map{"ref": $ref})
  let $level := normalize-space($fragment/@level)
  let $maxCiteDepth := xs:integer($fragment/@maxCiteDepth)
  let $citeType := normalize-unicode($fragment/@citeType)
  let $parentNodeId := normalize-space($fragment/@parentNodeId)
  let $nodeId := $fragment/@node-id
  let $members :=
    for $member in db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId][@parentNodeId=$nodeId]
    let $ref := normalize-space($member/@ref)
    let $levelMember :=xs:integer($member/@level)
    let $citeType := normalize-unicode($member/@citeType)
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
      <pair name="passage">{concat("/api/dts/document?id=", $resourceId, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
      <pair name="parent" type="object">{
        if ($parentNodeId)
        then 
          let $parentRef := normalize-space(db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@node-id=$parentNodeId]/@ref)
          return
            (
             <pair name="ref">{$parentRef}</pair>,
             <pair name="@type">CitableUnit</pair>
            )
        else 
          (
            <pair name="@id">{$resourceId}</pair>,
            <pair name="@type">resource</pair>
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
declare function utils:rangeNavigation($resourceId as xs:string, $start as xs:string, $end as xs:string, $down as xs:integer) {
  let $projectName := utils:getDbName($resourceId)
  let $url := concat("/api/dts/navigation?id=", $resourceId, "&amp;start=", $start, "&amp;end=", $end, if ($down) then (concat("&amp;down=", $down)) else ())
  let $frag1 := utils:getFragment($projectName, $resourceId, map{"ref": $start})
  let $maxCiteDepth := normalize-space($frag1/@maxCiteDepth)
  let $level := normalize-space($frag1/@level)
  return
    <json type="object">
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>
      <pair name="@id">{$url}</pair>
      <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>
      <pair name="level" type="number">{$level}</pair>
      <pair name="member" type="array">{
        utils:getFragmentsInRange($projectName, $resourceId, $start, $end, $down, "navigation")
      }</pair>
      <pair name="passage">{concat("/api/dts/document?id=", $resourceId, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
      <pair name="parent" type="null"></pair>
    </json>
};

(:~
: @todo le cas de figure suivant n'est pas pris en charge: 
: $start et $end ont 2 level différents + down > 0
: comment gérer ce cas de figure?
: faut-il ajouter des métadonnées (utils:getMandatory(), etc.)?
:)
declare function utils:getFragmentsInRange($projectName as xs:string, $resourceId as xs:string, $start as xs:string, $end as xs:string, $down as xs:integer, $context as xs:string) {
  let $firstFragment := utils:getFragment($projectName, $resourceId, map{"ref": $start})
  let $lastFragment := utils:getFragment($projectName, $resourceId, map{"ref": $end})
  let $firstFragmentLevel := xs:integer($firstFragment/@level)
  let $lastFragmentLevel := xs:integer($lastFragment/@level)
  return
    for $fragment in db:attribute-range($projectName, $start, $end, "n")/parent::dots:fragment[@resourceId = $resourceId]
    let $ref := normalize-space($fragment/@ref)
    let $level := xs:integer($fragment/@level)
    where
      if ($firstFragmentLevel = $lastFragmentLevel and $down = 0) 
      then $level = $firstFragmentLevel
      else 
        if ($firstFragmentLevel = $lastFragmentLevel and $down > 0)
        then $level = $firstFragmentLevel + $down
        else 
          let $minLevel := min(($firstFragmentLevel, $lastFragmentLevel))
          let $maxLevel := max(($firstFragmentLevel, $lastFragmentLevel))
          return
            $level >= $minLevel and $level <= $maxLevel
    return
      if ($context = "navigation")
      then
        <item type="object">
          <pair name="ref">{$ref}</pair>
          <pair name="level" type="number">{$level}</pair>
        </item>
      else db:get-id($projectName, $fragment/@node-id)
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
declare function utils:document($resourceId as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string) {
  let $project := utils:getDbName($resourceId)
  let $doc := db:get($project)/tei:TEI[@xml:id = $resourceId]
  let $header := $doc/tei:teiHeader
  let $idRef := 
    let $fragment := utils:getFragment($project, $resourceId, map{"ref": $ref})
    return
      $fragment/@node-id
  let $ref := 
    db:get-id($project, $idRef)
  return
    if ($ref)
    then
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{$ref}</dts:fragment>
      </TEI>
    else
      if ($start and $end)
      then
        let $sequence := utils:getFragmentsInRange($project, $resourceId, $start, $end, 0, "document")
        return
          <TEI xmlns="http://www.tei-c.org/ns/1.0">
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
declare function utils:getMandatory($resource as element(), $nav as xs:string) {
  let $resourceId := normalize-space($resource/@dtsResourceId)
  let $type := utils:getResourceType($resource)
  let $title := normalize-space($resource/dc:title)
  let $totalParents := if ($resource/@parentIds) then 1 else 0
  let $totalItems := 
    if ($nav = "parents")
    then
      $totalParents
    else
      if ($resource/@totalChildren) 
      then normalize-space($resource/@totalChildren) 
      else 0
  let $passage := concat("/api/dts/document?id=", $resourceId)
  let $references := concat("/api/dts/navigation?id=", $resourceId)
  return
    (
      <pair name="@id">{$resourceId}</pair>,
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
declare function utils:getDublincore($resource as element()) {
  let $dc := $resource/node()[starts-with(name(), "dc:")]
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
declare function utils:getExtensions($resource as element()) {
  let $extensions := $resource/node()[not(starts-with(name(), "dc:"))]
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

declare function utils:getDbName($resourceId) {
  normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $resourceId]/@dbName)
};

declare function utils:getResource($projectName as xs:string, $resourceId as xs:string) {
  db:get($projectName, $G:resourcesRegister)//dots:member/node()[@dtsResourceId = $resourceId]
};

declare function utils:getFragment($projectName as xs:string, $resourceId as xs:string, $options as map(*)) {
  let $id := map:get($options, "id")
  let $ref := map:get($options, "ref")
  let $start := map:get($options, "start")
  let $end := map:get($options, "end")
  return
    if ($id)
    then db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId]
    else
      if ($ref)
      then
        db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId][@ref = $ref] 
      else
        if ($start and $end)
        then () (: to do :)
        else ()
};

declare function utils:getResourceType($resource as element()) {
  if ($resource/name() = "document") then "resource" else $resource/name()
};

declare function utils:getChildMembers($projectName as xs:string, $resourceId as xs:string) {
  db:get($projectName, $G:resourcesRegister)//dots:member/node()[@parentIds = $resourceId]
};
