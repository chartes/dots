xquery version '3.0' ;

import module namespace utils = "resolver/utils";

declare variable $projectName := "cartulaires";
declare variable $resourceId := "cartulaires";

(: This function is used to build responses for the endpoint `/api/dts/collection`, with a query parameter `$id`.
: Exemple: `http://localhost:8080/api/dts/collection?id=cartulaires`
: This is the response whose response time seems quite long to us.
:)
utils:collectionById($resourceId, "", "") => prof:track(),

(:  
: It seems to me that the calculation of the variables `$member`, `$mandatoryMember`, `$dublincoreMember`, and `$extensionsMember` is the most time-consuming.
: (The list of functions below is not exhaustive. Other functions are called by `utils:collectionById()`, but they don't seem to cause any issues.) 
:)
let $resource := utils:getResource($projectName, $resourceId)
return
  (
    utils:getDbName($resourceId) => prof:track(),
    $resource => prof:track(),
    utils:getMandatory($projectName, $resource, "") => prof:track(),
    utils:getResourceType($resource) => prof:track(),
    utils:getDublincore($resource) => prof:track(),
    utils:getExtensions($resource) => prof:track(),
    for $member in utils:getChildMembers($projectName, $resourceId, "") 
    let $mandatoryMember := utils:getMandatory($projectName, $member, "") 
    let $dublincoreMember := utils:getDublincore($member) 
    let $extensionsMember := utils:getExtensions($member)
    return 
      (
        $member => prof:track(),
        $mandatoryMember => prof:track(),
        $dublincoreMember => prof:track(),
        $extensionsMember  => prof:track()
      )
)

