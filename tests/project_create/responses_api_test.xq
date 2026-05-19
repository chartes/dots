xquery version "4.0";

(:~  
: This module contains unit tests to verify the correct initialization of a DoTS BaseX database from a project directory.
: @author École nationale des chartes - Philippe Pons
: @since 2025-08-22
: @version  1.0
:)

declare variable $dbName external := "cartulaires";
declare variable $baseUri external := "http://localhost:8080/api/dts/collection";
declare variable $resourcesRegister := "dots/resources_register.xml";
declare variable $fragmentsRegister := "dots/fragments_register.xml";

(:~
: Smoke test for the DTS Collection API endpoint.
: Randomly samples up to 5% (max 30) of all resources from the resources register
: and checks that each returns a valid HTTP response.
: @return asserts HTTP status 200 and media type application/ld+json for each sampled resource
:)
declare %unit:test function local:checkCollectionStatus() {
  let $resources := db:get($dbName, $resourcesRegister)//*:member/node()/@dtsResourceId
  let $c := count($resources)
  let $sampleSize := min((max((1, round($c * 0.05))), 30))
  let $randomIndexes := (
    for $i in 1 to $sampleSize
    let $rand := random:integer($c) + 1
    return $rand
  )
  let $sample := for $i in distinct-values($randomIndexes)
                 return $resources[position() = $i]
  for $resource in $sample
  let $uri := concat($baseUri, "?id=", $resource)
  let $request := http:send-request(<http:request method='get' status-only='true'/>, $uri)
  let $status := normalize-space($request/@status)
  let $mediaType := normalize-space($request/http:body/@media-type)
  return
    (
      unit:assert-equals($status, "200"), 
      unit:assert-equals($mediaType, "application/ld+json")
    )
};

(:~
: Smoke test for the DTS Navigation API endpoint.
: Randomly samples up to 5% (max 30) of all fragments from the fragments register
: and checks that each returns a valid HTTP response.
: @return asserts HTTP status 200 and media type application/ld+json for each sampled fragment
:)
declare %unit:test function local:checkFragmentStatus() {
  let $fragments := db:get($dbName, $fragmentsRegister)//*:member/*:fragment
  let $c := count($fragments)
  let $sampleSize := min((max((1, round($c * 0.05))), 30))
  let $randomIndexes := (
    for $i in 1 to $sampleSize
    let $rand := random:integer($c) + 1
    return $rand
  )
  let $sample := for $i in distinct-values($randomIndexes)
                 return $fragments[position() = $i]
  for $fragment in $sample
  let $ref := $fragment/@ref
  let $resourceId := $fragment/@resourceId
  let $uri := concat($baseUri, "?resource=", $resourceId, "&amp;ref=", $ref, "&amp;down=-1")
  let $request := http:send-request(<http:request method='get' status-only='true'/>, $uri)
  let $status := normalize-space($request/@status)
  let $mediaType := normalize-space($request/http:body/@media-type)
  return
    (
      unit:assert-equals($status, "200"), 
      unit:assert-equals($mediaType, "application/ld+json")
    )
};

()