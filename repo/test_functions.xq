xquery version '3.0' ;

import module namespace utils = "resolver/utils";

(: utils:getDbName("ENCPOS_1972_18") => prof:track() :)
(: utils:getResource("encpos", "ENCPOS_1972_18") => prof:track() :)

(: let $resource := utils:getResource("encpos", "ENCPOS_1972_18")
return
  (
    utils:getDublincore($resource) => prof:track(),
    utils:getExtensions($resource) => prof:track()
  ) :)
  
(:  
: This function 
:)
(: utils:collectionById("cartulaires", "", "") => prof:track(), :)
let $resource := utils:getResource("cartulaires", "cartulaires")
return
  (
    utils:getDbName("cartulaires") => prof:track(),
    $resource => prof:track(),
    utils:getMandatory("cartulaires", $resource, "") => prof:track(),
    utils:getResourceType($resource) => prof:track(),
    utils:getDublincore($resource) => prof:track(),
    utils:getExtensions($resource) => prof:track()
  )
(: utils:getDbName("cartulaires") => prof:track(),
utils:getResource("cartulaires", "cartulaires") => prof:track(),
utils:getMandatory("cartulaires", "cartulaires", "") => prof:track(), :) 
(: utils:getResourceType("cartulaires") => prof:track() :)
