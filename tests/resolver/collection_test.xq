xquery version "4.0";

(:~  
: This module contains unit tests to verify the correct initialization of a DoTS BaseX database from a project directory.
: @author École nationale des chartes - Philippe Pons
: @since 2025-08-22
: @version  1.0
:)

declare variable $dbName external := "encpos";
declare variable $baseUri external := "http://localhost:8080/api/dts/collection";

(:~
: This test checks whether the BaseX database has been created successfully.
: @return An assertion that the database named $dbName exists.
:)
declare %unit:test function local:checkStatus() {
  let $request := http:send-request(<http:request method='get' status-only='true'/>, $baseUri)
  let $status := normalize-space($request/@status)
  let $mediaType := normalize-space($request/http:body/@media-type)
  return
    (
      unit:assert-equals($status, "200"), 
      unit:assert-equals($mediaType, "application/ld+json")
    )
};

declare function local:json() {
  let $json := json:doc($baseUri, map {"format": "attributes"})
  return
    $json
};

(: () :)
http:send-request(<http:request method='get' status-only='true'/>, $baseUri)







