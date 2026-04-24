xquery version "3.1";

(:~ 
 : Ce module permet de construire les réponses à fournir pour les urls spécifiées dans routes.xqm. 
 : @author  École nationale des chartes - Philippe Pons
 : @since 2023-05-15
 : @version  1.0
 :)

module namespace utils = "resolver/utils";

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots";
import module namespace functx = 'http://www.functx.com';

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dts = "https://w3id.org/dts/api#";
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

declare function utils:noCollection() as element(json) {
  <json type="object">
    <pair name="@context">https://dtsapi.org/context/v1.0.json</pair>
    <pair name="dtsVersion">1-alpha</pair>
    <pair name="@id">{utils_dots:getRootId()}</pair>
    <pair name="@type">Collection</pair>
    <pair name="title">{utils_dots:getRootTitle()}</pair>
    {
      let $desc := utils_dots:getRootDescription()
      where $desc
      return 
        <pair name="description">{$desc}</pair>
    }
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
declare function utils:collections() as element(json) {
  let $totalItems := xs:integer(db:get($G:dots)/dots:dbSwitch/dots:metadata/dots:totalProjects)
  let $content := (
    <pair name="@context">https://dtsapi.org/context/v1.0.json</pair>,
    <pair name="dtsVersion">1-alpha</pair>,
    <pair name="@id">{utils_dots:getRootId()}</pair>,
    <pair name="@type">Collection</pair>,
    <pair name="title">{utils_dots:getRootTitle()}</pair>,
    let $desc := utils_dots:getRootDescription()
    where $desc
    return 
      <pair name="description">{$desc}</pair>,
    <pair name="totalItems" type="number">{$totalItems}</pair>,
    <pair name="totalChildren" type="number">{$totalItems}</pair>,
    <pair name="totalParents" type="number">0</pair>,
    <pair name="member" type="array">{
      for $project in db:get($G:dots)//dots:member/dots:project
      let $resourceId := normalize-space($project/@dtsResourceId)
      let $dbName := $project/@dbName
      let $resourcesRegister := db:get($dbName, $G:resourcesRegister)
      let $resource := $resourcesRegister//dots:member/node()[@dtsResourceId = $resourceId]
      return
        if ($resource) 
        then 
          <item type="object">{
            utils:getMandatory("", $resource, ""),
            utils:getDublincore($resource),
            utils:getExtensions($resource)
          }</item> 
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
 : @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents. Ce paramètre permet de définir si les membres à lister sont les enfants ou  les parents
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
declare function utils:collectionById(
  $resourceId as xs:string,
  $nav as xs:string,
  $filter
) as element(json) {
  let $projectName := utils_dots:getDbName($resourceId)
  let $resource := utils_dots:getDocInRegister($projectName, $resourceId)
  return
    <json type="object">{
      let $mandatory := utils:getMandatory($projectName, $resource, $nav)
      let $type := utils:getResourceType($resource)
      let $dublincore := utils:getDublincore($resource)
      let $extensions := utils:getExtensions($resource)
      let $maxCiteDepth := normalize-space($resource/@maxCiteDepth)
      let $members := if ($type = "collection" or $nav = "parents") then (
        for $member in (
          if ($nav = "parents") then (
            for $parent in tokenize(normalize-space($resource/@parentIds))
            return utils_dots:getDocInRegister($projectName, $parent) 
          ) else (
            utils:getChildMembers($projectName, $resourceId, $filter)
          )
        )
        let $mandatoryMember := utils:getMandatory($projectName, $member, "")
        let $dublincoreMember := utils:getDublincore($member)
        let $extensionsMember := utils:getExtensions($member)
        return
          <item type="object">{
            $mandatoryMember,
            $dublincoreMember,
            $extensionsMember[node()]
          }</item>
      )
      let $response := (
        $mandatory,
        <pair name="dtsVersion">1-alpha</pair>,
        $dublincore,
        $extensions[node()],
        if ($members) then <pair name="member" type="array">{$members}</pair>
      )
      let $context := utils:getContext($projectName, $response)
      return ($response, $context)
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
declare function utils:navigation(
  $resourceId as xs:string,
  $ref as xs:string,
  $start as xs:string,
  $end as xs:string,
  $tree as xs:string,
  $filter,
  $down as xs:integer
) {
  if ($ref)
  then utils:refNavigation($resourceId, $ref, $down, $filter)
  else
    if ($start and $end)
    then utils:rangeNavigation($resourceId, $start, $end, $down, $tree, $filter)
    else utils:idNavigation($resourceId, $down, $tree, $filter)
      
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
declare function utils:idNavigation(
  $resourceId as xs:string,
  $down,
  $tree,
  $filter
) {
  let $projectName := utils_dots:getDbName($resourceId) 
  let $resource := utils_dots:getDocInRegister($projectName, $resourceId)
  let $maxCiteDepth := if ($resource/@maxCiteDepth != "") then xs:integer($resource/@maxCiteDepth) else 0
  let $members :=
    for $fragment in utils:getFragment($projectName, $resourceId, map {"id": $resourceId})
    let $level := xs:integer($fragment/@level)
    where 
      if ($down) 
      then 
        if ($down = -1)
        then xs:integer($level) <= $maxCiteDepth
        else xs:integer($level) <= $down 
      else xs:integer($level) = 1
    return
      $fragment
  let $filteredMembers :=
    if ($filter)
    then utils:filters($members, $filter)
    else
      $members
  let $treeMembers :=
    if ($tree)
    then utils:tree($members, $tree)
    else $filteredMembers
  let $response :=
    for $item in $treeMembers
    let $fragInfo := utils:getFragmentInfo($item)
    return
      <item type="object">{$fragInfo}</item>
  let $base-uri := substring-before(request:uri(), "/api")
  let $url := concat($base-uri, "/api/dts/navigation?id=", $resourceId)
  let $context := utils:getContext($projectName, $response)
  return
    <json type="object">{
      <pair name="dtsVersion">1-alpha</pair>,
      <pair name="@id">{$url}</pair>,
      <pair name="@type">Navigation</pair>,
      utils:getResourcesInfo($projectName, $resource),
      if ($response)
      then
        <pair name="member" type="array">{$response}</pair> else (),
      <pair name="parent" type="null"></pair>,
      $context
    }</json>
};

declare function utils:getResourcesInfo(
  $projectName as xs:string,
  $resource
) {
  let $resourceId := normalize-space($resource/@dtsResourceId)
  let $maxCiteDepth := normalize-space($resource/@maxCiteDepth)
  let $uri := substring-before(request:uri(), "/api")
  return
    <pair name="resource" type="object">
      <pair name="@id">{$resourceId}</pair>
      <pair name="@type">Resource</pair>
      <pair name="document">{concat($uri, "/api/dts/document?resource=", $resourceId, "{&amp;ref,start,end,mediaType}")}</pair>
      <pair name="collection">{
        let $parentIds := $resource/@parentIds
        return
          if (contains($parentIds, " "))
          then 
            (
              attribute {"type"} {"array"},
              let $tokenize := tokenize($parentIds, " ")
              for $coll in $tokenize
              return
                <item>{concat($uri, "/api/dts/collection?id=", $coll), "{&amp;nav}"}</item>
            )
          else
            concat($uri, "/api/dts/collection?id=", $parentIds, "{&amp;nav}")
      }</pair>
      <pair name="navigation">{concat($uri, "/api/dts/document?resource=", $resourceId, "{&amp;ref,down,start,end}")}</pair>
      <pair name="citationTrees" type="object">
        <pair name="@type">CitationTree</pair>
        <pair name="maxCiteDepth" type="number">{
          if ($maxCiteDepth)
          then xs:integer($maxCiteDepth)
          else 0
        }</pair>
        {
          let $document := utils_dots:findPathDoc($projectName, $resourceId, false())
          let $refsDecl := $document//*:refsDecl
          where $refsDecl
          return utils:getCitationTrees($refsDecl)
        }
        <pair name="mediaTypes" type="array">
          <item>xml</item>
          <item>html</item>
        </pair>
      </pair>
    </pair>
};

declare function utils:getFragmentInfo(
  $item as element(dots:fragment)
) {
  let $ref := normalize-space($item/@ref)
  let $level := xs:integer($item/@level)
  let $parent := 
    if ($level = 1)
    then ""
    else normalize-space($item/@parentNodeRef)
  let $citeType := normalize-unicode($item/@citeType)
  let $dc := utils:getDublincore($item)
  let $extensions := utils:getExtensions($item)
  return (
    <pair name="identifier">{$ref}</pair>,
    <pair name="@type">CitableUnit</pair>,
    <pair name="level" type="number">{$level}</pair>,
    <pair name="parent">{
      if ($level = 1)
      then (attribute {"type"} {"null"}, "")
      else $parent
    }</pair>,
    if ($citeType) then <pair name="citeType">{$citeType}</pair> else <pair name="citeType" type="null"/>,
    $dc,
    $extensions
  )
};

declare function utils:tree(
  $sequence,
  $tree as xs:string
) {
  for $fragment in $sequence
  where $fragment/@citeType = $tree
  return $fragment
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
declare function utils:refNavigation(
  $resourceId as xs:string,
  $ref as xs:string,
  $down as xs:integer,
  $filter
) {
  let $projectName := utils_dots:getDbName($resourceId)
  let $resource := utils_dots:getDocInRegister($projectName, $resourceId)
  let $base-uri := substring-before(request:uri(), "/api")
  let $url := concat($base-uri, "/api/dts/navigation?id=", $resourceId, "&amp;ref=", $ref)
  let $fragment := utils:getFragment($projectName, $resourceId, map { "ref": $ref })
  return
    if (not($fragment))
    then web:error(404, "Error 404 : Not Found")
    else
  let $level := xs:integer($fragment/@level[1])
  let $maxCiteDepth := xs:integer($fragment/@maxCiteDepth)
  let $followingFrag := xs:integer($fragment/following::dots:fragment[@level = $level][@resourceId = $resourceId][1]/@node-id)
  let $nodeId := xs:integer($fragment/@node-id)
  let $refInfos := utils:getFragmentInfo($fragment)
  let $members :=
    if ($down != -2)
    then 
      for $member in db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId]
      let $levelMember := xs:integer($member/@level)
      where
        let $nodeIdMember := xs:integer($member/@node-id)
        return
          if ($down = -1)
          then $nodeIdMember >= $nodeId and $nodeIdMember < $followingFrag 
          else
            let $maxLevel := if ($down + $level > $maxCiteDepth) then $maxCiteDepth else $down + $level
            return
              $nodeIdMember >= $nodeId and $nodeIdMember < $followingFrag and $levelMember <= $maxLevel
      return
        $member
    else
      if ($down = 0) 
      then 
        let $fragmentParent := $fragment/@parentNodeRef
        for $member in db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment[@resourceId = $resourceId]
        return
          if ($fragmentParent)
          then
            $member[@parentNodeRef = $fragmentParent]
          else 
            $member[not(@parentNodeRef)]
      else ()
  let $membersFiltered :=
    if ($filter)
    then utils:filters($members, $filter)
    else $members
  let $response :=
    for $item in $membersFiltered
    let $itemInfo := utils:getFragmentInfo($item)
    return
      <item type="object">{$itemInfo}</item>
  let $context := utils:getContext($projectName, $response)
  return
    <json type="object">
      <pair name="dtsVersion">1-alpha</pair>
      <pair name="@id">{$url}</pair>
      <pair name="@type">Navigation</pair>
      {utils:getResourcesInfo($projectName, $resource),
      <pair name="ref" type="object">{$refInfos}</pair>}
      {
        if ($response) 
        then <pair name="member" type="array">{$response}</pair> 
        else 
          <pair name="member" type="array">
            <item type="object">{$refInfos}</item>
          </pair>
      }
      {$context}
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
declare function utils:rangeNavigation(
  $resourceId as xs:string,
  $start as xs:string,
  $end as xs:string,
  $down as xs:integer,
  $tree,
  $filter
) {
  let $projectName := utils_dots:getDbName($resourceId)
  let $resource := utils_dots:getDocInRegister($projectName, $resourceId)
  let $base-uri := substring-before(request:uri(), "/api")
  let $url := concat($base-uri, "/api/dts/navigation?id=", $resourceId, "&amp;start=", $start, "&amp;end=", $end, if ($down) then (concat("&amp;down=", $down)) else ())
  let $frag1 := utils:getFragment($projectName, $resourceId, map { "ref": $start })
  let $fragLast := utils:getFragment($projectName, $resourceId, map { "ref": $end })
  return
    if (not($frag1) or not($fragLast))
    then
      let $message := "Error 404 : Not Found"
      return
        web:error(404, $message)
    else
  let $maxCiteDepth := normalize-space($frag1/@maxCiteDepth)
  let $level := normalize-space($frag1/@level)
  let $startFrag := utils:getFragmentInfo($frag1) 
  let $endFrag := utils:getFragmentInfo($fragLast) 
  let $members := utils:getSequenceInRange($projectName, $resourceId, $start, $end, $down)
  let $membersFiltered :=
    if ($filter)
    then utils:filters($members, $filter)
    else $members
  let $treeMembers :=
    if ($tree)
    then utils:tree($membersFiltered, $tree)
    else $membersFiltered
  let $response :=
    for $item in $treeMembers
    let $itemInfo := utils:getFragmentInfo($item)
    return
      <item type="object">{$itemInfo}</item>
  let $context := utils:getContext($projectName, $response)
  return
    <json type="object">
      <pair name="dtsVersion">1-alpha</pair>
      <pair name="@id">{$url}</pair>
      <pair name="@type">Navigation</pair>
      {utils:getResourcesInfo($projectName, $resource)}
      <pair name="start" type="object">{$startFrag}</pair>
      <pair name="end" type="object">{$endFrag}</pair>
      <pair name="member" type="array">{
      $response
      }</pair>
      {$context}
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
 : @todo revoir le paramètre "tree" qui n'est actuellement pas pris en charge
 :)
declare function utils:document(
  $resourceId as xs:string,
  $ref as xs:string,
  $start as xs:string,
  $end as xs:string,
  $tree as xs:string,
  $filter,
  $excludeFragments as xs:boolean := false()
) {
  let $project := utils_dots:getDbName($resourceId)
  let $doc := utils_dots:findPathDoc($project, $resourceId)
  let $fragments := 
    if ($excludeFragments)
    then ()
    else
      if ($ref)
      then 
        let $frag := utils:getFragment($project, $resourceId, map { "ref": $ref })
        return
          if ($frag)
          then $frag
          else
            let $message := "Error 404 : Not Found"
            return
              web:error(400, $message)
      else 
        if ($start and $end)
        then 
          let $range := utils:getDocSequenceInRange($project, $resourceId, $start, $end, $tree, $filter)
          return
            if ($range)
            then $range
            else
              let $message := "Error 404 : Not Found"
              return
                web:error(400, $message)
        else ()
  (: let $treeResult :=
    if ($tree)
    then 
      for $treeFragment in $fragments
      where $treeFragment/@citeType = $tree
      return $treeFragment
    else $fragments :)
  let $filterResult := 
    if ($filter) 
    then 
      if ($fragments)
      then 
        if (count($fragments) > 1)
        then
          utils:filters($fragments, $filter)
        else
          let $level := $fragments/@level
          let $currentFragId := xs:integer($fragments/@node-id)
          let $nextFrag := db:get($project, $G:fragmentsRegister)//dots:fragment[@node-id = $currentFragId]/following::dots:fragment[@level = $level][1]
          let $nextFragId := $nextFrag/@node-id
          let $fragsInRef := 
            for $frags in db:get($project, $G:fragmentsRegister)//dots:fragment[@resourceId = $resourceId][@level >= xs:integer($level)]
            let $node-id := xs:integer($frags/@node-id)
            where $node-id >= $currentFragId and $node-id < $nextFragId
            return
              utils:filters($frags, $filter)
          return
            $fragsInRef
      else
        let $fullFragments := db:get($project, $G:fragmentsRegister)//dots:fragment
        return utils:filters($fullFragments, $filter)
    else $fragments
  let $excludeFrags := 
    if ($excludeFragments)
    then utils:excludeFragments($project, $resourceId, $ref)
    else ()
  return
    if ($filterResult or $excludeFrags)
    then
      if ($filterResult)
      then
        <TEI xmlns="http://www.tei-c.org/ns/1.0">
          <dts:wrapper xmlns:dts="https://w3id.org/dts/api#">{
            for $fragment in $filterResult
            return
              db:get-id($project, $fragment/@node-id)
          }</dts:wrapper>
        </TEI>
      else $excludeFrags
    else 
      if ($tree or $filter)
      then
        let $message := "Error 404 : no fragment available"
        return
          web:error(404, $message)
      else 
        $doc
};

declare function utils:excludeFragments(
  $project as xs:string,
  $resourceId as xs:string,
  $ref as xs:string
) {
  let $register := db:get($project, $G:fragmentsRegister)
  let $fragment := $register//dots:fragment[@resourceId = $resourceId][@ref = $ref]
  let $node-id := $fragment/@node-id
  let $node := db:get-id($project, $node-id)
  return
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <dts:wrapper xmlns:dts="https://w3id.org/dts/api#">{
      let $childs :=
        for $child in $node/node()
        let $id := $child/@xml:id
        return
          if ($id)
          then 
            let $node-id := db:node-id($child)
            let $frag := $register//dots:fragment[@node-id = $node-id]
            return
              if ($frag)
              then 
                ()
              else $child
          else $child
      return
        $childs
  }</dts:wrapper>
  </TEI>
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
 : @todo "download" peut-être un array. Ce n'est actuellement pas pris en compte
 :)
declare function utils:getMandatory(
  $dbName as xs:string,
  $resource as element(),
  $nav as xs:string
) as element(pair)* {
  let $resourceId := normalize-space($resource/@dtsResourceId)
  let $type := utils:getResourceType($resource)
  let $desc := normalize-space($resource/*:description)
  let $totalParents := count(tokenize($resource/@parentIds))
  let $totalChildren := if ($type = ("resource", "Resource")) then (
    0
  ) else (
    xs:integer($resource/@totalChildren)
  )
  let $uri := substring-before(request:uri(), "/api")
  let $resourceLink := if ($type = ("resource", "Resource")) then (
    <pair name="collection">{concat($uri, "/api/dts/collection?id=", $resourceId, "{?nav}")}</pair>,
    <pair name="document">{concat($uri, "/api/dts/document?resource=", $resourceId, "{?ref,start,end,tree,mediaType}")}</pair>,
    <pair name="navigation">{concat($uri, "/api/dts/navigation?resource=", $resourceId, "{?ref,start,end,tree,down}")}</pair>,
    let $downloads := $resource/*:download
    where $downloads
    return
      (: PP. Attention: correction de download pour en faire un tableau, selon la spéc DTS.
      Mais, cela va poser un problème pour DoTS-vue qui attend ici un objet. Voir avec Victor :)
      <pair name="download" type="object">{
        for $download in $downloads
        return 
          switch ($download)
          case ($download[ends-with(., "html")]) return <pair name="text/html">{normalize-space($download)}</pair>
          default return <pair name="application/tei+xml">{normalize-space($download)}</pair>
          (: utils:getStringJson($download/@key, $download) :)
      }</pair>
  )
  let $citationTrees := if ($type = ("resource", "Resource")) then (
  let $document := utils_dots:findPathDoc($dbName, $resourceId, false())
  let $refsDecl := $document//*:refsDecl
  where $refsDecl
    return utils:getCitationTrees($refsDecl)
  )
  return (
    <pair name="@id">{$resourceId}</pair>,
    <pair name="@type">{functx:capitalize-first($type)}</pair>,
    <pair name="title">{normalize-space($resource/dct:title[1])}</pair>,
    if ($desc) then <pair name="description">{$desc}</pair>,
    <pair name="totalItems" type="number">{if ($nav) then $totalParents else $totalChildren}</pair>,
    <pair name="totalChildren" type="number">{$totalChildren}</pair>,
    <pair name="totalParents" type="number">{$totalParents}</pair>,
    $resourceLink,
    if ($citationTrees) then (
      <pair name="citationTrees" type="object">
        <pair name="@type">CitationTree</pair>
        <pair name="maxCiteDepth" type="number">{normalize-space($resource/@maxCiteDepth)}</pair>
        {$citationTrees}
      </pair>
    ),
    if ($type = ("resource", "Resource")) then (
      <pair name="mediaTypes" type="array">
        <item>application/tei+xml</item>
        <item>text/html</item>
      </pair>
    )
  )
};

declare function utils:getCitationTrees(
  $node as element()
) as element(pair) {
  <pair name="citeStructure" type="object">{
    for $cite in $node/*:citeStructure
    let $citeType := normalize-space($cite/@unit)
    return
      (
        <pair name="@type">CiteStructure</pair>,
        if ($citeType) 
        then <pair name="citeType">{$citeType}</pair>
        else <pair name="citeType" type="null"/>,
        if ($cite/*:citeStructure)
        then utils:getCitationTrees($cite)
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
declare function utils:getDublincore(
  $resource as element()
) {
  let $dct := $resource/node()[namespace-uri(.) = "http://purl.org/dc/terms/"]
  where $dct
  return
    <pair name="dublinCore" type="object">{
      for $metadata in $dct
      let $key := $metadata/name()
      let $elementName := substring-after($key, "dct:")
      let $countKey := count($dct/name()[. = $key])
      group by $key
      order by $key
      return
        if ($countKey > 1 or $metadata[@type = "array"])
        then
          utils:getArrayJson($elementName[1], $metadata)
        else
          if ($key)
          then utils:getStringJson($elementName, $metadata)
    }</pair>
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
declare function utils:getExtensions(
  $resource as element()
) {
  let $extensions := $resource/node()[not(starts-with(name(), "dct:"))]
  where $extensions
  return
    <pair name="extensions" type="object">{
      for $metadata in $extensions
      let $key := $metadata/name()
      where $key != "download"
      where $key != "description"
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
        if ($countKey > 1 or $metadata/@key or $metadata[@type="array"])
        then
          utils:getArrayJson($name[1], $metadata)
        else
          if ($countKey = 0)
          then ()
          else
           utils:getStringJson($name, $metadata)
    }</pair>
};


(:~ 
 : Cette fonction permet de construire un tableau XML de métadonnées
 : @return élément XML qui sera ensuite sérialisée en JSON selon le format "attributes" proposé par BaseX
 : @param $key chaîne de caractères qui servira de clef JSON
 : @param $metada séquence XML
 :)
declare function utils:getArrayJson(
  $key as xs:string,
  $metadata
) {
  <pair name="{$key}" type="array">{
    for $meta in $metadata
    return
      <item>{
        let $key := $meta/@key
        return if ($key) then (
          attribute {"type"} {"object"},
          utils:getStringJson($key, $meta)
        ) else (
          let $type := $meta/@type
          where $type and $type != "array"
          return attribute {"type"} {$type},
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
declare function utils:getStringJson(
  $key,
  $metadata
) {
  if ($key = "download")
  then ()
  else
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
declare function utils:getContext(
  $db as xs:string,
  $response
) {
  <pair name="@context" type="array">
    <item>https://dtsapi.org/context/v1.0.json</item>
    <item type="object">
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
              case ($namespace[. = "dct"]) return <pair name="dct">{"http://purl.org/dc/terms/"}</pair>
              case ($namespace[. = "html"]) return <pair name="html">{"http://www.w3.org/1999/xhtml"}</pair>
              default return () 
  }
   </item>
</pair>
};

(:~  
 : Cette fonction permet de retrouver, dans la base de données BaseX $projectName, dans le registre DoTS "dots/fragments_register.xml" le(s) fragment(s)  de la resource $resourceId
 : @return réponse XML
 : @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
 : @param $resourceId chaîne de caractère identifiant une resource
 : @param $options map réunissant les informations pour définir le(s) fragments à trouver
 :)
declare function utils:getFragment(
  $projectName as xs:string,
  $resourceId as xs:string,
  $options as map(*) := {}
) {
  let $id := map:get($options, "id")
  let $ref := map:get($options, "ref")
  return db:get($projectName, $G:fragmentsRegister)//dots:member/dots:fragment
    [@resourceId = $resourceId]
    [$id or @ref = $ref]
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
declare function utils:getFragmentsInRange(
  $projectName as xs:string,
  $resourceId as xs:string,
  $start,
  $end,
  $down as xs:integer,
  $filter
) {
  let $firstFragment := utils:getFragment($projectName, $resourceId, map { "ref": $start })
  let $lastFragment := utils:getFragment($projectName, $resourceId, map { "ref": $end })
  let $s := xs:integer($firstFragment/@node-id)
  let $e := xs:integer($lastFragment/@node-id)

  let $members := db:get($projectName, $G:fragmentsRegister)//dots:fragment[@node-id[. >= $s and . <= $e]]
  let $result :=
    if ($filter)
    then utils:filters($members, $filter)
    else $members
  return
  let $firstFragmentLevel := xs:integer($firstFragment/@level)
  let $lastFragmentLevel := xs:integer($lastFragment/@level)
  for $fragment in $result
  let $ref := normalize-space($fragment/@ref)
  let $level := xs:integer($fragment/@level)
  where (
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
  )
  return
    <item type="object">
      <pair name="ref">{$ref}</pair>
      <pair name="level" type="number">{$level}</pair>
    </item>
};

declare function utils:getSequenceInRange(
  $projectName as xs:string,
  $resourceId as xs:string,
  $start,
  $end,
  $down as xs:integer
) {
  let $firstFragment := utils:getFragment($projectName, $resourceId, map { "ref": $start })
  let $lastFragment := utils:getFragment($projectName, $resourceId, map { "ref": $end })
  let $s := xs:integer($firstFragment/@node-id)
  let $e := xs:integer($lastFragment/@node-id)

  let $members := db:get($projectName, $G:fragmentsRegister)//dots:fragment[@node-id[. >= $s and . <= $e]]
  let $firstFragmentLevel := xs:integer($firstFragment/@level)
  let $lastFragmentLevel := xs:integer($lastFragment/@level)
  for $fragment in $members
  let $ref := normalize-space($fragment/@ref)
  let $level := xs:integer($fragment/@level)
  where (
    if ($firstFragmentLevel = $lastFragmentLevel and $down = 0) 
    then $level = $firstFragmentLevel
    else 
      if ($firstFragmentLevel = $lastFragmentLevel and $down > 0)
      then $level <= $firstFragmentLevel + $down
      else 
        let $minLevel := min(($firstFragmentLevel, $lastFragmentLevel))
        let $maxLevel := max(($firstFragmentLevel, $lastFragmentLevel))
        return
          $level >= $minLevel and $level <= $maxLevel
  )
  return $fragment
};

declare function utils:getDocSequenceInRange(
  $projectName as xs:string,
  $resourceId as xs:string,
  $start,
  $end,
  $tree,
  $filter
) {
  let $firstFragment := utils:getFragment($projectName, $resourceId, map { "ref": $start })
  let $lastFragment := utils:getFragment($projectName, $resourceId, map { "ref": $end })
  let $s := xs:integer($firstFragment/@node-id)
  let $e := xs:integer($lastFragment/@node-id)

  let $members := db:get($projectName, $G:fragmentsRegister)//dots:fragment[@node-id[. >= $s and . <= $e]]
  return if ($tree or $filter) then (
    $members
  ) else (
    let $firstFragmentLevel := xs:integer($firstFragment/@level)
    let $lastFragmentLevel := xs:integer($lastFragment/@level)
    for $fragment in $members
    let $level := xs:integer($fragment/@level)
    where (
      if ($firstFragmentLevel = $lastFragmentLevel) then (
        $level = $firstFragmentLevel
      ) else (
        let $minLevel := min(($firstFragmentLevel, $lastFragmentLevel))
        let $maxLevel := max(($firstFragmentLevel, $lastFragmentLevel))
        return $level >= $minLevel and $level <= $maxLevel
      )
    )
    return $fragment
  )
};

(:~  
 : Cette fonction permet de retrouver le type d'une ressource (ressource de type collections ou ressource de type resource)
 : @return chaîne de caractère: "collections" ou "resources"
 : @param $resource élément XML
 :)
declare function utils:getResourceType(
  $resource as element()
) {
  let $name := name($resource)
  return if ($name = "document") then "resource" else $name
};

(:~  
 : Cette fonction permet de retrouver dans une base de données BaseX $projectName, dans le registre "dots/resources_register.xml", les membres enfants de la resource $resourceId
 : @return séquence XML
 : @param $projectName chaîne de caratère permettant de retrouver la base de données BaseX concernée
 : @param $resourceId chaîne de caractère identifiant une resource
 :)
declare function utils:getChildMembers(
  $projectName as xs:string,
  $resourceId as xs:string,
  $filter
) {
  let $members :=
    for $child in db:get($projectName, $G:resourcesRegister)//dots:member/node()[contains(@parentIds, $resourceId)]
    return
      if ($child/@parentIds = $resourceId)
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
    then utils:filters($members, $filter)
    else $members
};

declare function utils:filters(
  $elements as element()*,
  $filter
) as element()* {
  let $numberOfMatch := functx:number-of-matches($filter, "=")
  return if ($numberOfMatch = 1) then (
    utils:getResultFilter($elements, $filter)
  ) else if ($numberOfMatch > 1) then (
    let $tokenizeFilter := tokenize($filter, "AND")
    let $count := count($tokenizeFilter)
    let $filter1 := $tokenizeFilter[1]
    let $filtersToDo := if ($count > 2) then (
      substring-after(substring-after($filter, $filter1), "AND")
    ) else (
      $tokenizeFilter[2]
    )
    let $newSequence := utils:getResultFilter($elements, $filter1)
    return utils:filters($newSequence, $filtersToDo)
  )
};

declare function utils:getResultFilter(
  $elements as element()*,
  $filter as xs:string
) as element()* {
  let $key := normalize-space(substring-before($filter, "="))
  let $value := normalize-space(substring-after($filter, "="))
  for $element in $elements
  where $element/node()[name() = $key] = $value
  return $element
};
