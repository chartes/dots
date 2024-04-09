xquery version "3.1";

(:~ 
: Ce module permet de construire les réponses à fournir pour les urls spécifiées dans routes.xqm. 
: @author  École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
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
: Cette variable permet de choisir l'identifiant d'une collection "racine" (pour le endpoint Collection sans paramètre d'identifiant)
: @todo pouvoir choisir l'identifiant de collection Route à un autre endroit? (le title du endpoint collection sans paramètres)
: à déplacer dans globals.xqm ou dans un CLI?
:)

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions d'entrée dans le endPoint "Collection" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

declare function utils:noCollection() {
  <json type="object">
    <pair name="@context">https://distributed-text-services.github.io/specifications/context/1-alpha1.json</pair>
    <pair name="dtsVersion">1-alpha</pair>
    <pair name="@id">{$G:root}</pair>
    <pair name="@type">Collection</pair>
    <pair name="title">{$G:rootTitle}</pair>
    <pair name="totalItems" type="number">0</pair>
    <pair name="totalChildren" type="number">0</pair>
    <pair name="totalParents" type="number">0</pair>
  </json>
};

(:~ 
: Cette fonction permet de lister les collections DTS dépendant d'une collection racine $utils:root.
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:getContex
: @see utils.xqm;utils:getMandatory
:)
declare function utils:collections() {
  let $totalItems := xs:integer(db:get($G:dots)/dots:dbSwitch/dots:metadata/dots:totalProjects)
  let $content :=
    (
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1-alpha1.json</pair>,
      <pair name="dtsVersion">1-alpha</pair>,
      <pair name="@id">{$G:root}</pair>,
      <pair name="@type">Collection</pair>,
      <pair name="title">{$G:rootTitle}</pair>,
      <pair name="totalItems" type="number">{$totalItems}</pair>,
      <pair name="totalChildren" type="number">{$totalItems}</pair>,
      <pair name="totalParents" type="number">0</pair>,
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
              utils:getMandatory("", $resource, "")
            }</pair> 
          else ()
      }</pair>
    )
  return
    <json type="object">{
      $content
    }</json>
};

(:~ 
: Cette fonction permet de construire la réponse d'API d'une collection DTS identifiée par le paramètre $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resourceId chaîne de caractère permettant d'identifier la collection ou le document concerné. Ce paramètre vient de routes.xqm;routes:collections
: @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents. Ce paramètre permet de définir si les membres à lister sont les enfants ou les parents
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:getDbName
: @see utils.xqm;utils:getResource
: @see utils.xqm;utils:getMandatory
: @see utils.xqm;utils:getResourceType
: @see utils.xqm;utils:getDublincore
: @see utils.xqm;utils:getExtensions
: @see utils.xqm;utils:getChildMembers
: @see utils.xqm;utils:getContext
:)
declare function utils:collectionById($resourceId as xs:string, $nav as xs:string, $filter) {
  let $projectName := utils:getDbName($resourceId)
  let $resource := utils:getResource($projectName, $resourceId)
  return
    <json type="object">{
      let $mandatory := utils:getMandatory($projectName, $resource, $nav)
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
              return 
                if (contains($idParent, " "))
                then 
                  let $parents := tokenize($idParent)
                  for $parent in $parents
                  return
                    utils:getResource($projectName, $parent) 
                else
                  utils:getResource($projectName, $idParent) 
            else utils:getChildMembers($projectName, $resourceId, $filter) 
          let $mandatoryMember := utils:getMandatory($projectName, $member, "")
          let $dublincoreMember := utils:getDublincore($member)
          let $extensionsMember := utils:getExtensions($member)
          return
            <item type="object">{
              $mandatoryMember,
              $dublincoreMember,
              if ($extensionsMember/node()) then $extensionsMember else ()
            }</item>
        else ()
      let $response := 
        (
          $mandatory,
          $dublincore,
          if ($extensions/node()) then $extensions else (),
          if ($members) then <pair name="member" type="array">{$members}</pair>,
          if ($maxCiteDepth) then <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair> else ()
        )
      let $context := utils:getContext($projectName, $response)
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
: - utils:idNavigation si seul le paramètre $resourceId est disponible 
Chacune de ces fonctions permet de construire la réponse pour le endpoint Navigation de l'API DTS pour la resource identifiée par le paramètre $id
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resourceId chaîne de caractère permettant d'identifier la resource concernée. Ce paramètre vient de routes.xqm;routes.collections
: @param $ref chaîne de caractère permettant d'identifier un passage précis d'une resource. Ce paramètre vient de routes.xqm;routes.collections
: @param $start chaîne de caractère permettant de spécifier le début d'une séquence de passages d'une resource à renvoyer. Ce paramètre vient de routes.xqm;routes.collections
: @param $end chaîne de caractère permettant de spécifier la fin d'une séquence de passages d'une resource à renvoyer. Ce paramètre vient de routes.xqm;routes.collections
: @param $down entier indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:utils:refNavigation
: @see utils.xqm;utils:utils:rangeNavigation
: @see utils.xqm;utils:utils:idNavigation
:)
declare function utils:navigation($resourceId as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $filter, $down as xs:integer) {
  if ($ref)
  then utils:refNavigation($resourceId, $ref, $down, $filter)
  else
    if ($start and $end)
    then utils:rangeNavigation($resourceId, $start, $end, $down, $filter)
    else utils:idNavigation($resourceId, $down, $filter)
      
};

(:~  
Cette fonction permet de construire la réponse d'API DTS pour le endpoint Navigation dans le cas où seul l'identifiant de la ressource est donnée.
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resourceId chaîne de caractère permettant d'identifier la resource concernée
: @param $down entier indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @see utils.xqm;utils:getDbName
: @see utils.xqm;utils:getResource
: @see utils.xqm;utils:getFragment
: @see utils.xqm;utils:getDublincore
: @see utils.xqm;utils:getExtensions
:)
declare function utils:idNavigation($resourceId as xs:string, $down, $filter) {
  let $projectName := utils:getDbName($resourceId) 
  let $resource := utils:getResource($projectName, $resourceId)
  let $members :=
    for $fragment in utils:getFragment($projectName, $resourceId, map {"id": $resourceId})
    let $level := xs:integer($fragment/@level)
    where if ($down) then xs:integer($level) = $down else xs:integer($level) = 1
    return
      $fragment
  let $filteredMembers :=
    if ($filter)
    then utils:filters($members, $filter)    
  let $response :=
    for $item in if ($filteredMembers) then $filteredMembers else $members
    let $ref := normalize-space($item/@ref)
    let $level := xs:integer($item/@level)
    let $citeType := normalize-unicode($item/@citeType)
    let $dc := utils:getDublincore($item)
    let $extensions := utils:getExtensions($item)
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
  let $passage := 
    if ($resource/name() = "document")
    then <pair name="passage">{concat("/api/dts/document?id=", $resourceId, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
    else ()
  let $url := concat("/api/dts/navigation?id=", $resourceId)
  let $maxCiteDepth := if ($resource/@maxCiteDepth != "") then xs:integer($resource/@maxCiteDepth) else 0
  return
    <json type="object">{
      <pair name="@context">https://distributed-text-services.github.io/specifications/context/1.0.0draft-2.json</pair>,
      <pair name="@id">{$url}</pair>,
      <pair name="level" type="number">0</pair>,
      <pair name="maxCiteDepth" type="number">{$maxCiteDepth}</pair>,
      if ($response)
      then
        <pair name="member" type="array">{$response}</pair> else (),
        $passage,
      <pair name="parent" type="null"></pair>
    }</json>
};

(:~ 
: Cette fonction permet de construire la réponse pour le endpoint Navigation de l'API DTS pour le passage identifié par $ref de la resource $resourceId
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resourceId chaîne de caractère permettant d'identifier la collection ou le document concerné. Ce paramètre vient de routes.xqm;routes.collections
: @param $ref chaîne de caractère permettant d'identifier un passage précis d'une resource. Ce paramètre vient de routes.xqm;routes.collections
: @param $down entier indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @see utils.xqm;utils:getDbName
: @see utils.xqm;utils:getFragment
: @see utils.xqm;utils:getDublincore
: @see utils.xqm;utils:getExtensions
: @todo revoir le listing des members dans les cas où maxCiteDepth > 1
: @todo revoir bug sur dts:extensions qui apparaît même si rien
: @todo revoir <pair name="parent"></pair> => ajouter un attribut @parentResource sur les fragments
:)
declare function utils:refNavigation($resourceId as xs:string, $ref as xs:string, $down as xs:integer, $filter) {
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
    return
      $member
  let $membersFiltered :=
    if ($filter)
    then utils:filters($members, $filter)
    else ()
  let $response :=
    for $item in if ($membersFiltered != "") then $membersFiltered else $members
    let $ref := normalize-space($item/@ref)
    let $levelMember :=xs:integer($item/@level)
    let $citeType := normalize-unicode($item/@citeType)
    let $dc := utils:getDublincore($item)
    let $extensions := utils:getExtensions($item)
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
        if ($response) then <pair name="member" type="array">{$response}</pair> else ()
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
            <pair name="@type">Resource</pair>
          )
      }</pair>
    </json>
};

(:~ 
: Cette fonction permet de construire la réponse pour le endpoint Navigation de l'API DTS pour la séquence de passages suivis entre $start et $end de la resource $resourceId
: @return réponse donnée en XML pour être sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resourceId chaîne de caractère permettant d'identifier la collection ou le document concerné. Ce paramètre vient de routes.xqm;routes.collections
: @param $start chaîne de caractère permettant de spécifier le début d'une séquence de passages d'un document à renvoyer
: @param $end chaîne de caractère permettant de spécifier la fin d'une séquence de passages d'un document à renvoyer
: @param $down entier indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @see utils.xqm;utils:getDbName
: @see utils.xqm;utils:getFragment
: @see utils.xqm;utils:getFragmentsInRange
:)
declare function utils:rangeNavigation($resourceId as xs:string, $start as xs:string, $end as xs:string, $down as xs:integer, $filter) {
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
        utils:getFragmentsInRange($projectName, $resourceId, $start, $end, $down, "navigation", $filter)
      }</pair>
      <pair name="passage">{concat("/api/dts/document?id=", $resourceId, "{&amp;ref}{&amp;start}{&amp;end}")}</pair>
      <pair name="parent" type="null"></pair>
    </json>
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions d'entrée dans le endPoint "Document" de l'API DTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction donne accès au document ou à un fragment du document identifié par le paramètre $id
: @return document ou fragment de document XML
: @param $resourceId chaîne de caractère permettant l'identification du document XML
: @param $ref chaîne de caractère indiquant un fragment à citer
: @param $start chaîne de caractère indiquant le début d'un passage cité
: @param $end chaîne de caractère indiquant la fin d'un passage cité
: @see utils.xqm;utils:getDbName
: @see utils.xqm;utils:getFragment
: @see utils.xqm;utils:getFragmentsInRange
: @todo revoir la gestion de start et end!
:)
declare function utils:document($resourceId as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $citeType as xs:string, $filter) {
  let $project := utils:getDbName($resourceId)
  let $doc := 
    if (db:get($project)/tei:TEI[@xml:id = $resourceId])
    then db:get($project)/tei:TEI[@xml:id = $resourceId]
    else 
      for $document in db:get($project)/tei:TEI
      where ends-with(db:path($document), $resourceId)
      return $document
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
        let $sequence := utils:getFragmentsInRange($project, $resourceId, $start, $end, 0, "document", $filter)
        return
          <TEI xmlns="http://www.tei-c.org/ns/1.0">
            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{$sequence}</dts:fragment>
          </TEI>
      else
        if ($citeType)
        then
          <TEI xmlns="http://www.tei-c.org/ns/1.0">{
            for $fragment in db:get($project, $G:fragmentsRegister)//dots:member/dots:fragment
            where $fragment/@citeType = $citeType
            where $fragment/@resourceId = $resourceId
            let $node-id := $fragment/@node-id
            return              
              <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{db:get-id($project, $node-id)}</dts:fragment>
          }</TEI>
        else
          if ($filter)
          then 
            let $fragments :=
              for $fragment in db:get($project, $G:fragmentsRegister)//dots:fragment[@resourceId = $resourceId]
              return
                $fragment
            return
              <TEI xmlns="http://www.tei-c.org/ns/1.0">{
                let $filteredFragments := utils:filters($fragments, $filter)
                for $frag in $filteredFragments
                let $node-id := $frag/@node-id
                return
                  <dts:fragment xmlns:dts="https://w3id.org/dts/api#">{db:get-id($project, $node-id)}</dts:fragment>
              }</TEI> 
          else
            $doc
};

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
Fonctions "utiles"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:)

(:~ 
: Cette fonction permet de préparer les données obligatoires à servir pour le endpoint Collection de l'API DTS: @id, @type, @title, @totalItems (à compléter probablement)
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resource élément XML où se trouvent toutes les informations à servir en réponse
: @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents. Ce paramètre permet de définir si les membres à lister sont les enfants ou les parents
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collections (fonction qui fait appel à la fonction ici présente)
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
: @see utils.xqm;utils:getResourceType
:)
declare function utils:getMandatory($dbName as xs:string, $resource as element(), $nav as xs:string) {
  let $resourceId := normalize-space($resource/@dtsResourceId)
  let $type := utils:getResourceType($resource)
  let $title := 
    let $t := $resource/*:title[1]
    where in-scope-prefixes($t)[1] = "dc"
    return
      normalize-space($t)
  let $desc := normalize-space($resource/description)
  let $totalParents := 
    if ($resource/@parentIds) 
    then 
      if (contains($resource/@parentIds, " "))
      then 
        let $parents := tokenize($resource/@parentIds)
        let $c := count($parents)
        return
          $c
      else 1 
    else 0
  let $totalChildren :=
    if ($type = "resource")
    then 0
    else xs:integer($resource/@totalChildren)
  let $passage := 
    if ($type = "collection")
    then ()
    else <pair name="document">{concat("/api/dts/document?resource=", $resourceId, "{$ref,start,end,tree,mediaType}")}</pair>
  let $references := 
    if ($type = "collection")
    then ()
    else <pair name="navigation">{concat("/api/dts/navigation?resource=", $resourceId, "{$ref,start,end,tree}")}</pair>
  let $citationTrees :=
    if ($type = "resource")
    then
      let $document := db:get($dbName)/tei:TEI[@xml:id = $resourceId]
      let $refsDecl := $document//tei:refsDecl
      return
        if ($refsDecl)
        then 
          utils:getCitationTrees($refsDecl)
        else ()
    else ()
  return
    (
      <pair name="@id">{$resourceId}</pair>,
      <pair name="@type">{functx:capitalize-first($type)}</pair>,
      <pair name="dtsVersion">1-alpha</pair>,
      <pair name="title">{$title}</pair>,
      if ($desc) then <pair name="description">{$desc}</pair> else (),
      <pair name="totalItems" type="number">{if ($nav) then $totalParents else $totalChildren}</pair>,
      <pair name="totalChildren" type="number">{$totalChildren}</pair>,
      <pair name="totalParents" type="number">{$totalParents}</pair>,
      $passage,
      $references,
      if ($citationTrees)
      then
        <pair name="citationTrees" type="object">
          <pair name="@type">CitationTree</pair>
          <pair name="maxCiteDepth" type="number">{normalize-space($resource/@maxCiteDepth)}</pair>
          {$citationTrees}
        </pair>
    )
};

declare function utils:getCitationTrees($node) {
  <pair name="citeStructure" type="object">{
    for $cite in $node/node()
    let $citeType := normalize-space($cite/@unit)
    return
      (
        if ($citeType) then <pair name="citeType">{$citeType}</pair>,
        if ($cite/tei:citeStructure)
        then 
          utils:getCitationTrees($cite)
      )
  }</pair>
};

(:~ 
: Cette fonction permet de préparer les données en Dublincore pour décrire une collection ou une resource
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resource élément XML où se trouvent toutes les informations à servir en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
: @see utils.xqm;utils:getArrayJson
: @see utils.xqm;utils:getStringJson
:)
declare function utils:getDublincore($resource as element()) {
  let $dc := $resource/node()[in-scope-prefixes(.)[1] = "dc"]
  return
    if ($dc)
    then
      <pair name="dublincore" type="object">{
        for $metadata in $dc
        let $key := $metadata/name()
        let $elementName :=
          if (starts-with($key, "dc:"))
          then substring-after($key, "dc:")
          else $key
        let $countKey := count($dc/name()[. = $key])
        group by $key
        order by $key
        return
          if ($countKey > 1)
          then
            utils:getArrayJson($elementName, $metadata)
          else
            if ($key)
            then utils:getStringJson($elementName, $metadata)
            else ()
      }</pair>
    else ()
};

(:~ 
: Cette fonction permet de préparer toutes les données non Dublincore utilisées pour décrire une collection ou une resource
: @return séquence XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $resource élément XML où se trouvent toutes les informations à servir en réponse
: @see https://docs.basex.org/wiki/JSON_Module#Attributes
: @see utils.xqm;utils:collectionById (fonction qui fait appel à la fonction ici présente)
: @see utils.xqm;utils:getArrayJson
: @see utils.xqm;utils:getStringJson
:)
declare function utils:getExtensions($resource as element()) {
  let $extensions := $resource/node()[not(starts-with(name(), "dc:"))]
  return
    if ($extensions)
    then
      <pair name="extensions" type="object">{
        for $metadata in $extensions
        let $key := $metadata/name()
        let $prefix := in-scope-prefixes($metadata)[1]
        where $prefix != "dc"
        where $key != ""
        let $ns := namespace-uri($metadata)
        let $name := 
          if (contains($key, ":")) 
          then $key 
          else 
            if ($ns = "https://github.com/chartes/dots/")
            then $key
            else concat($prefix, ":", $key)
        let $countKey := count($extensions/name()[. = $key])
        group by $key
        order by $key
        return
          if ($countKey > 1)
          then
            utils:getArrayJson($name[1], $metadata)
          else
            if ($countKey = 0)
            then ()
            else
             utils:getStringJson($name, $metadata)
      }</pair>
    else ()
};


(:~ 
: Cette fonction permet de construire un tableau XML de métadonnées
: @return élément XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
: @param $key chaîne de caractères qui servira de clef JSON
: @param $metada séquence XML
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
: @todo utiliser la fonction namespace:uri() pour une meilleur gestion des namespaces?
:)
declare function utils:getContext($db as xs:string, $response) {
  <pair name="@context" type="object">
    <pair name="dts">https://distributed-text-services.github.io/specifications/context/1-alpha1.json</pair>
    {if ($response//*:pair[@name="dublincore"] or $response[@name="dublincore"]) then <pair name="dc">http://purl.org/dc/elements/1.1/</pair> else ()}
    {if ($response = "")
    then ()
    else
      if ($db != "")
      then
        let $map := db:get($db, concat($G:metadata, "dots_metadata_mapping.xml"))/dots:metadataMap
        return
          for $name in $response//@name
          where contains($name, ":")
          let $namespace := substring-before($name, ":")
          group by $namespace
          return
            if ($map)
            then 
              let $listPrefix := in-scope-prefixes($map)
              where $namespace = $listPrefix
              let $uri := namespace-uri-for-prefix($namespace, $map)
              return
                <pair name="{$namespace}">{$uri}</pair>
            else
              switch ($namespace)
              case ($namespace[. = "dc"]) return <pair name="dc">{"http://purl.org/dc/elements/1.1/"}</pair>
              case ($namespace[. = "dct"]) return <pair name="dct">{"http://purl.org/dc/terms/"}</pair>
              case ($namespace[. = "html"]) return <pair name="html">{"http://www.w3.org/1999/xhtml"}</pair>
              default return () 
  }</pair>
};

(:~  
: Cette fonction permet de retrouver le nom de la base de données BaseX à laquelle appartient la resource $resourceId
: @return réponse XML
: @param $resourceId chaîne de caractère identifiant une resource
:)
declare function utils:getDbName($resourceId) {
  normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $resourceId]/@dbName)
};



(:~  
: Cette fonction permet de retrouver, dans la base de données BaseX $projectName, dans le registre DoTS "dots/resources_register.xml" la resource $resourceId
: @return réponse XML
: @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
: @param $resourceId chaîne de caractère identifiant une resource
:)
declare function utils:getResource($projectName as xs:string, $resourceId as xs:string) {
  db:get($projectName, $G:resourcesRegister)//dots:member/node()[@dtsResourceId = $resourceId]
};

(:~  
: Cette fonction permet de retrouver, dans la base de données BaseX $projectName, dans le registre DoTS "dots/fragments_register.xml" le(s) fragment(s)  de la resource $resourceId
: @return réponse XML
: @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
: @param $resourceId chaîne de caractère identifiant une resource
: @param $options map réunissant les informations pour définir le(s) fragments à trouver
:)
declare function utils:getFragment($projectName as xs:string, $resourceId as xs:string, $options as map(*)) {
  let $id := map:get($options, "id")
  let $ref := map:get($options, "ref")
  return
    if ($id)
    then 
      db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId]
    else
      if ($ref)
      then
        let $fragments :=
          db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId][@ref = $ref] 
          return
            $fragments
      else ()
};

(:~
: Cette fonction permet de retrouver, dans la base de données BaseX $projectName, dans le registre DoTS "dots/fragments_register.xml" la séquence de fragments de la resource $resourceId entre $start et $end
: @return réponse XML si $context est "document", réponse XML ensuite sérialisées en JSON (format: attributes) si $context est "navigation"
: @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
: @param $resourceId chaîne de caractère identifiant une resource
: @param $start chaîne de caractère identifiant un fragment dans la resource $resourceId
: @param $end chaîne de caractère identifiant un fragment dans la resource $resourceId
: @param $down entier indiquant le niveau de profondeur des membres citables à renvoyer en réponse
: @param $context chaîne de caractère (navigation ou document) permettant de connaître le contexte d'utilisation de la fonction
: @see utils.xqm;utils:getFragment
: @error ne fonctionne pas dans le cas de fragments avec un attribut @xml:id
: @todo le cas de figure suivant n'est pas pris en charge: 
: $start et $end ont 2 level différents + down > 0
: comment gérer ce cas de figure?
: faut-il ajouter des métadonnées (utils:getMandatory(), etc.)?
:)
declare function utils:getFragmentsInRange($projectName as xs:string, $resourceId as xs:string, $start, $end, $down as xs:integer, $context as xs:string, $filter) {
  let $firstFragment := utils:getFragment($projectName, $resourceId, map{"ref": $start})
  let $lastFragment := utils:getFragment($projectName, $resourceId, map{"ref": $end})
  let $firstFragmentLevel := xs:integer($firstFragment/@level)
  let $lastFragmentLevel := xs:integer($lastFragment/@level)
  let $s := xs:integer($firstFragment/@node-id)
  let $e := xs:integer($lastFragment/@node-id)
  return
    let $members :=
      for $fragment in db:get($projectName, $G:fragmentsRegister)//dots:fragment
      where $fragment/@node-id >= $s and $fragment/@node-id <= $e
      return
        $fragment
    let $result :=
      if ($filter)
      then utils:filters($members, $filter)
      else $members
    return
    for $fragment in $result
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

(:~  
: Cette fonction permet de retrouver le type d'une ressource (ressource de type collections ou ressource de type resource)
: @return chaîne de caractère: "collections" ou "resources"
: @param $resource élément XML
:)
declare function utils:getResourceType($resource as element()) {
  if ($resource/name() = "document") then "resource" else $resource/name()
};

(:~  
: Cette fonction permet de retrouver dans une base de données BaseX $projectName, dans le registre "dots/resources_register.xml", les membres enfants de la resource $resourceId
: @return séquence XML
: @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
: @param $resourceId chaîne de caractère identifiant une resource
:)
declare function utils:getChildMembers($projectName as xs:string, $resourceId as xs:string, $filter) {
  let $members :=
    for $child in db:get($projectName, $G:resourcesRegister)//dots:member/node()[contains(@parentIds, $resourceId)]
    return
      if ($child[@parentIds = $resourceId])
      then $child
      else
        let $candidatParent := tokenize($child/@parentIds)
        where 
          for $candidat in $candidatParent
          where $candidat = $resourceId
          return
            <candidat>{$candidat}</candidat>
        return 
         $child
  return
    if ($filter)
    then 
      utils:filters($members, $filter)
    else
      $members
};

declare function utils:filters($sequence, $filter) {
  let $numberOfMatch := functx:number-of-matches($filter, "=")
  return
    if ($numberOfMatch = 1) 
    then utils:getResultFilter($sequence, $filter)
    else 
      if ($numberOfMatch > 1)
      then
        let $tokenizeFilter := tokenize($filter, "AND")
        let $count := count($tokenizeFilter)
        let $filter1 := $tokenizeFilter[1]
        let $filtersToDo :=
          if ($count > 2)
          then 
            substring-after(substring-after($filter, $filter1), "AND")
          else $tokenizeFilter[2]
        return
          (
            let $newSequence := utils:getResultFilter($sequence, $filter1)
            return
              utils:filters($newSequence, $filtersToDo)
          )
  };

declare function utils:getResultFilter($sequence, $filter) {
  let $metadata := normalize-space(substring-before($filter, "="))
  let $value := normalize-space(substring-after($filter, "="))
  return
    for $element in $sequence
    where $element/node()[name() = $metadata] = $value
    return
      $element
};



