xquery version "3.1";

(:~ 
: Ce module regroupe les urls à servir pour la mise en oeuvre de l'API DTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
: @todo Revoir en profondeur les namespaces
:)

module namespace routes="https://github.com/chartes/dots/api/routes";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace utils = "https://github.com/chartes/dots/api/utils" at "utils.xqm";

(:~  
: Cette fonction gère le point d'entrée de l'API DTS
: @return réponse JSON pour le endpoint EntryPoint
: @see https://distributed-text-services.github.io/specifications/Entry.html#base-api-endpoint
:)
declare
  %rest:path("/api/dts")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
function routes:entryPoint() {
 <json type="object">
   <pair name="@context">/api/dts/EntryPoint.jsonld</pair>
   <pair name="@id">/api/dts</pair>
   <pair name="@type">EntryPoint</pair>
   <pair name="collections">/api/dts/collections</pair>
   <pair name="documents">/api/dts/document</pair>
   <pair name="navigation">/api/dts/navigation</pair>
 </json>
};

(:~  
: Cette fonction dispatche vers les fonctions permettant de donner les informations concernants la/les collection(s) DTS existante(s) si le paramètre $id n'est pas précisé. Sinon, les informations concernant la collection DTS identifiée par le paramètre $id
: @return réponse JSON pour les endpoints Collections de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @see https://distributed-text-services.github.io/specifications/Collections-Endpoint.html
: @todo compléter les paramètres 
:) 
declare
  %rest:path("/api/dts/collections")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("id", "{$id}", "")
  %rest:query-param("nav", "{$nav}", "")
function routes:collections($id as xs:string, $nav as xs:string) {
  if ($id)
  then
    utils:collectionById($id, $nav)
   else
     utils:collections()
};

(:~  
: Cette fonction dispatche vers les fonctions permettant de donner les informations du endpoint Navigation pour la collection $id
: @return réponse JSON pour le endpoint Navigation de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @see https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html
: @todo compléter les paramètres 
:) 
declare
  %rest:path("/api/dts/navigation")
  %rest:GET
  %output:method("json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("id", "{$id}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("down", "{$down}", 0)
function routes:navigation($id as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $down as xs:integer) {
  utils:navigation($id, $ref, $start, $end, $down)
};

(:~ 
: Cette fonction permet de renvoyer un document ou un fragment du document XML identifié par le paramètre $id
: @return réponse XML-TEI pour les endpoints Document de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier le document XML (obligatoire)
: @see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
:)
declare
  %rest:path("/api/dts/document")
  %rest:GET
  %output:method("xml")
  %rest:produces("application/tei+xml")
  %rest:query-param("id", "{$id}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("format", "{$format}", "")
function routes:document($id as xs:string, $ref as xs:string, $start as xs:string, $end as xs:string, $format as xs:string) {
  let $ref := if ($ref) then $ref else ""
  let $start := if ($start) then $start else ""
  let $end := if ($end) then $end else ""
  let $result := utils:document($id, $ref, $start, $end)
  return
    if ($format)
    then 
      let $f :=
        switch ($format)
        case ($format[. = "html"]) return "text/html;"
        case ($format[. = "txt"]) return "text/plain"
        default return "xml"
      let $style := concat($G:webapp, $G:xsl)
      let $project := db:get($G:dots)//node()[@dtsResourceId = $id]/@dbName
      let $doc := db:get($project)/*:TEI[@xml:id = $id]
      let $trans := 
        if ($format = "html")
        then
          xslt:transform($result, $style)
        else  $result
      return
        (
          <rest:response>
            <http:response status="200">
              <http:header name="Content-Type" value="{concat($f, ' charset=utf-8')}"/>
            </http:response>
          </rest:response>,
          $trans
        )
    else
      $result
};





