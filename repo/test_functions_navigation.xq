xquery version '4.0' ;

import module namespace utils_dots = "utils_dots";
import module namespace G = "globals";
import module namespace functx = 'http://www.functx.com';

declare namespace dots = "https://github.com/chartes/dots/";

(:~ Generates a JSON object formatted as a DTS Navigation endpoint response.
: It includes all fragments between the given start and end identifiers, optionally restricted by structure type and metadata filters. 
: @param $resourceId (xs:string()) : identifier of the TEI document.
: @param $start (xs:string()) : identifier of the starting node.
: @param $end (xs:string()) : identifier of the ending node.
: @param $down (xs:integer()) : number of citation levels to descend from the range bounds.
: @param $tree : citation structure type to restrict the result.
: @param $filter : optional key=value filter applied to metadata.
: @return A JSON object representing the "range" response of the Navigation endpoint.
:)
declare function local:rangeNavigation(
  $resourceId as xs:string,
  $start as xs:string,
  $end as xs:string,
  $down as xs:integer,
  $tree,
  $filter
) {
  let $projectName := utils_dots:getDbName($resourceId)
  let $resource := utils_dots:getDocInRegister($projectName, $resourceId)
  let $url := concat("/api/dts/navigation?id=", $resourceId, "&amp;start=", $start, "&amp;end=", $end, if ($down) then (concat("&amp;down=", $down)) else ())
  let $frag1 := local:getFragment($projectName, $resourceId, map { "ref": $start })
  let $fragLast := local:getFragment($projectName, $resourceId, map { "ref": $end })
  return
    if (not($frag1) or not($fragLast))
    then
      let $message := "Error 404 : Not Found"
      return
        web:error(404, $message)
    else
  let $maxCiteDepth := normalize-space($frag1/@maxCiteDepth)
  let $level := normalize-space($frag1/@level)
  let $startFrag := local:getFragmentInfo($frag1) 
  let $endFrag := local:getFragmentInfo($fragLast) 
  let $members := local:getSequenceInRange($projectName, $resourceId, $start, $end, $down)
  let $membersFiltered :=
    if ($filter)
    then local:filters($members, $filter)
    else $members
  let $treeMembers :=
    if ($tree)
    then local:tree($membersFiltered, $tree)
    else $membersFiltered
  let $response :=
    for $item in $treeMembers
    let $itemInfo := local:getFragmentInfo($item)
    return
      <item type="object">{$itemInfo}</item>
  let $context := local:getContext($projectName, $response)
  return
    <json type="object">
      <pair name="dtsVersion">1-alpha</pair>
      <pair name="@id">{$url}</pair>
      <pair name="@type">Navigation</pair>
      {local:getResourcesInfo($projectName, $resource)}
      <pair name="start" type="object">{$startFrag}</pair>
      <pair name="end" type="object">{$endFrag}</pair>
      <pair name="member" type="array">{
      $response
      }</pair>
      {$context}
    </json>
};
(:~ Retrieves a single <dots:fragment> element from the fragments register of a project, based on its @resourceId and either @id or @ref.
: @param $projectName (xs:string) : The name of the project.
: @param $resourceId (xs:string) : The identifier of the resource.
: @param $options (map{}) : A map optionally containing "id" or "ref".
: @return A matching <dots:fragment> element.
:)
declare function local:getFragment(
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

(:~ Builds a JSON object (as <pair> elements) with all relevant metadata about a single TEI fragment: identifier, level, parent reference, citation type, and any associated Dublin Core or extension metadata.
: @param $item (element(dots:fragment)) : the <dots:fragment> element to analyze.
: @return A sequence of <pair> elements representing the fragment metadata.
:)
declare function local:getFragmentInfo(
  $item as element(dots:fragment)
) {
  let $ref := normalize-space($item/@ref)
  let $level := xs:integer($item/@level)
  let $parent := 
    if ($level = 1)
    then ""
    else normalize-space($item/@parentNodeRef)
  let $citeType := normalize-unicode($item/@citeType)
  let $dc := local:getDublincore($item)
  let $extensions := local:getExtensions($item)
  return (
    <pair name="identifier">{$ref}</pair>,
    <pair name="@type">CitableUnit</pair>,
    <pair name="level" type="number">{$level}</pair>,
    <pair name="parent">{
      if ($level = 1)
      then (attribute {"type"} {"null"}, "")
      else $parent
    }</pair>,
    if ($citeType) then <pair name="citeType">{$citeType}</pair> else (),
    $dc,
    $extensions
  )
};

(:~ Extracts and serializes all child elements in the Dublin Core namespace as a JSON object.
: @param $resource (element()) : the <dots:fragment> element to analyze.
: @return A <pair> of type "object" containing dc:* elements as key-value pairs, handling multiple values as arrays.
:)
declare function local:getDublincore(
  $resource as element(dots:fragment)
) {
  let $dc := $resource/node()[namespace-uri(.) = "http://purl.org/dc/elements/1.1/"]
  where $dc
  return
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
        if ($countKey > 1 or $metadata/@key)
        then
          local:getArrayJson($elementName[1], $metadata)
        else
          if ($key)
          then local:getStringJson($elementName, $metadata)
    }</pair>
};

(:~ Extracts all non-Dublin Core metadata from a fragment and formats them into a structured JSON object.  
: @param $resource (element()) : the <dots:fragment> element to analyze.
: @return A <pair> of type "object" containing extension metadata, preserving namespaces and supporting multiple values.
:)
declare function local:getExtensions(
  $resource as element()
) {
  let $extensions := $resource/node()[not(starts-with(name(), "dc:"))]
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
        if ($countKey > 1 or $metadata/@key)
        then
          local:getArrayJson($name[1], $metadata)
        else
          if ($countKey = 0)
          then ()
          else
           local:getStringJson($name, $metadata)
    }</pair>
};

(:~ Converts multiple metadata entries into a JSON array.
: @param $key (xs:string()) : name of the JSON property.
: @param $metadata : sequence of XML elements to convert.
: @return A JSON <pair> containing the array.
:)
declare function local:getArrayJson(
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
          local:getStringJson($key, $meta)
        ) else (
          let $type := $meta/@type
          where $type
          return attribute {"type"} {$type},
          normalize-space($meta)
        )
      }</item>
  }</pair>
};

(:~ Converts a single XML element into a JSON key/value pair. 
: @param $key (xs:string()) : name of the JSON property.
: @param $metadata : the XML element to convert.
: @return A single JSON <pair>.
:)
declare function local:getStringJson(
  $key as xs:string,
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

(:~ Retrieves all fragments located between two identifiers.
: @param $projectName : name of the project.
: @param $resourceId : identifier of the document.
: @param $start : start identifier.
: @param $end : end identifier.
: @param $down : number of levels to descend in the hierarchy.
: @return A sequence of <dots:fragment> elements.
:)
declare function local:getSequenceInRange(
  $projectName as xs:string,
  $resourceId as xs:string,
  $start,
  $end,
  $down as xs:integer
) {
  let $firstFragment := local:getFragment($projectName, $resourceId, map { "ref": $start })
  let $lastFragment := local:getFragment($projectName, $resourceId, map { "ref": $end })
  let $s := xs:integer($firstFragment/@node-id)
  let $e := xs:integer($lastFragment/@node-id)

  let $members := db:get($projectName, $G:fragmentsRegister)//dots:fragment[@node-id = $s to $e]
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


(:~ Applies multiple key=value filters to a sequence of fragments.
: @param $elements (element()*) : sequence of elements to filter.
: @param $filter : map of key=value filters.
: @return The filtered sequence matching all key/value pairs.
:)
declare function local:filters(
  $elements as element()*,
  $filter
) as element()* {
  let $numberOfMatch := functx:number-of-matches($filter, "=")
  return if ($numberOfMatch = 1) then (
    local:getResultFilter($elements, $filter)
  ) else if ($numberOfMatch > 1) then (
    let $tokenizeFilter := tokenize($filter, "AND")
    let $count := count($tokenizeFilter)
    let $filter1 := $tokenizeFilter[1]
    let $filtersToDo := if ($count > 2) then (
      substring-after(substring-after($filter, $filter1), "AND")
    ) else (
      $tokenizeFilter[2]
    )
    let $newSequence := local:getResultFilter($elements, $filter1)
    return local:filters($newSequence, $filtersToDo)
  )
};

(:~ Applies a single key=value filter to a sequence of fragments.
: @param $elements (element()*) : sequence of elements
: @param $filter (xs:string()) : a map with a single key=value filter.
: @return The filtered sequence.
:)
declare function local:getResultFilter(
  $elements as element()*,
  $filter as xs:string
) as element()* {
  let $key := normalize-space(substring-before($filter, "="))
  let $value := normalize-space(substring-after($filter, "="))
  for $element in $elements
  where $element/node()[name() = $key] = $value
  return $element
};

declare function local:tree(
  $sequence,
  $tree as xs:string
) {
  for $fragment in $sequence
  where $fragment/@citeType = $tree
  return $fragment
};

(:~ Generates a JSON-LD @context object from the declared namespaces. 
: @param $db (xs:string()) : name of the database.
: @param $response : XML element containing metadata.
: @return A JSON <pair> for @context.
:)
declare function local:getContext(
  $db as xs:string,
  $response
) {
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

(:~ Constructs a JSON object to describe a fragment, including links to DTS endpoints.
: @param $projectName (xs:string()) : name of the project.
: @param $resource : fragment with all metadatas.
: @return A JSON object describing the fragment.
:)
declare function local:getResourcesInfo(
  $projectName as xs:string,
  $resource
) {
  let $resourceId := normalize-space($resource/@dtsResourceId)
  let $maxCiteDepth := normalize-space($resource/@maxCiteDepth)
  return
    <pair name="resource" type="object">
      <pair name="@id">{$resourceId}</pair>
      <pair name="@type">Resource</pair>
      <pair name="document">{concat("/api/dts/document?resource=", $resourceId, "{&amp;ref,start,end,mediaType}")}</pair>
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
                <item>{concat("/api/dts/collection?id=", $coll), "{&amp;nav}"}</item>
            )
          else
            concat("/api/dts/collection?id=", $parentIds, "{&amp;nav}")
      }</pair>
      <pair name="navigation">{concat("/api/dts/document?resource=", $resourceId, "{&amp;ref,down,start,end}")}</pair>
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
          return local:getCitationTrees($refsDecl)
        }
        <pair name="mediaTypes" type="array">
          <item>xml</item>
          <item>html</item>
        </pair>
      </pair>
    </pair>
};

(:~ Recursively traverses TEI citation structures to build their JSON representation.
: @param $node : a <citeStructure> element.
: @return A JSON array representing the citation tree.
:)
declare function local:getCitationTrees(
  $node as element()
) as element(pair) {
  <pair name="citeStructure" type="array">{
    for $cite in $node/*:citeStructure
    let $citeType := normalize-space($cite/@unit)
    return
      <item type="object">
        <pair name="@type">CiteStructure</pair>
        {
          if ($citeType) then (
            <pair name="citeType">{$citeType}</pair>
          ) else (
            <pair name="citeType" type="null"/>
          ),
          if ($cite/*:citeStructure)
          then local:getCitationTrees($cite)
       }
     </item>
  }</pair>
};


local:rangeNavigation("moliere_avare", "a2", "a4", 1, "", "")






















