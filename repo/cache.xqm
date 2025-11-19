module namespace cache = 'cache';

import module namespace utils_dots = "utils_dots"; 

(: BaseX 12.1: cache entries will expire in 1 hours :)
declare variable $cache:OPTIONS := { 'expiry': xs:dayTimeDuration('PT1H') };

declare function cache:cache(
  $resourceId as xs:string,
  $name as xs:string,
  $code as fn(*)
) as item()* {
  (: check if we want to cache results for this resource :)
  let $db := utils_dots:getDbName($resourceId)
  return if(utils_dots:cache($resourceId)) then (
    let $cache-key := $db || ':' || $name
    let $entry := store:get($cache-key)
    let $entry-ts := $entry?timestamp
    let $db-ts := db:property($db, 'timestamp')
    
    return if(exists($entry) and $entry-ts = $db-ts) then (
      $entry?contents
    ) else (
      (: store outdated cache entries :)
      for $key in store:keys()
      where starts-with($key, $db || ':')
      return store:remove($key),
      
      let $contents := $code()
      let $value := { 'timestamp': $db-ts, 'contents': $contents }
      return (
        store:put($cache-key, $value (:, $cache:OPTIONS :)),
        $contents
      )
    )
  ) else (
    $code()
  )
};
