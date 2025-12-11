module namespace cache = 'cache';

import module namespace utils_dots = "utils_dots"; 

(:~ Single cache entry. :)
declare variable $cache:VALUE := 'value';

declare function cache:cache(
  $dbName          as xs:string,
  $resourceId      as xs:string,
  $name            as xs:string,
  $code            as fn(*),
  $store-in-cache  as fn(*) := true#0 (: fn() { true() } :)
) as item()* {
  (: check if we want to cache results for this resource :)
  if(utils_dots:cache($dbName, $resourceId)) then (
    let $store := replace($name, '\W', '_')
    let $entry := store:get($store, $dbName)
    (: let $entry-ts := $entry?timestamp :)
    let $db-ts := db:property($dbName, 'timestamp')
    return (
      if(exists($entry) (: and $entry-ts = $db-ts :)) 
      then $entry?contents
      else 
        if($store-in-cache()) 
        then 
          (
        (: store outdated cache entries
        for $key in store:keys()
        where starts-with($key, $db || ':')
        return store:remove($key),
        :)
          let $contents := $code()
          let $value := { 'timestamp': $db-ts, 'contents': $contents }
          return (
            store:put($store, $value, $dbName),
            $contents
          )
        ) 
        else $code(),
      store:close($dbName)
    )
  ) else (
    $code()
  )
};