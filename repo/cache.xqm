module namespace cache = 'cache';

import module namespace utils_dots = "utils_dots"; 

(: BaseX 12.1: cache entries will expire in 1 hours :)
declare variable $cache:OPTIONS := { 'expiry': xs:dayTimeDuration('PT1H') };
(:~ Single cache entry. :)
declare variable $cache:VALUE := 'value';

declare function cache:cache(
  $resourceId      as xs:string,
  $name            as xs:string,
  $code            as fn(*),
  $store-in-cache  as fn(*) := true#0 (: fn() { true() } :)
) as item()* {
  (: check if we want to cache results for this resource :)
  let $db := utils_dots:getDbName($resourceId)
  return if(utils_dots:cache($db, $resourceId)) then (
    let $store := replace($name, '\W', '_')
    let $entry := store:get($cache:VALUE, $store)
    (: let $entry-ts := $entry?timestamp :)
    let $db-ts := db:property($db, 'timestamp')
    return (
      if(exists($entry) (: and $entry-ts = $db-ts :)) then (
        $entry?contents
      ) else if($store-in-cache()) then (
        (: store outdated cache entries
        for $key in store:keys()
        where starts-with($key, $db || ':')
        return store:remove($key),
        :)
        
        let $contents := $code()
        let $value := { 'timestamp': $db-ts, 'contents': $contents }
        return (
          store:put($cache:VALUE, $value, $store),
          $contents
        )
      ) else (
        $code()
      ),
      store:close($store)
    )
  ) else (
    $code()
  )
};
