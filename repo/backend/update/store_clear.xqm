xquery version "4.0";

module namespace store_clear = "backend/update/store_clear";

declare namespace dc = "http://purl.org/dc/elements/1.1/";

declare namespace dots = "https://github.com/chartes/dots/";

declare updating function store_clear:clear(
  $dbName as xs:string,
  $resourceId as xs:string
) {
  
  store:delete($dbName),
  for $keys in store:keys($dbName)
  where starts-with($keys, concat("resource=", $resourceId))
  where starts-with($keys, concat("id=", $resourceId))
  return
    store:remove($keys, $dbName)
};