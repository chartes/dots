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
  
utils:collectionById("ENCPOS_1972_18", "", "") => prof:track() 