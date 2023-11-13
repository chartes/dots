xquery version "3.1";

(:~ 
: Ce module regroupe les urls à servir pour la mise en oeuvre de l'API DTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
:)

module namespace routes="https://github.com/chartes/dots/api/routes";

import module namespace functx = "http://www.functx.com";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace utils = "https://github.com/chartes/dots/api/utils" at "utils.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

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
: Cette fonction gère le endpoint Collections. Elle dispatche vers les fonctions permettant de donner les informations concernants la/les collection(s) DTS existante(s) si le paramètre $id n'est pas précisé. Sinon, les informations concernant la collection DTS identifiée par le paramètre $id
: @return réponse JSON pour le endpoints Collections de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents. Ce paramètre permet de définir si les membres à lister sont les enfants ou les parents
: @see https://distributed-text-services.github.io/specifications/Collections-Endpoint.html
: @see utils.xqm;utils:collectionById
: @see utils.xqm;utils:collections
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
: Cette fonction gère le endpoint Navigation. Elle dispatche vers les fonctions permettant de donner les informations du endpoint Navigation pour la collection $id
: @return réponse JSON pour le endpoint Navigation de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier une collection DTS
: @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
: @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
: @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
: @param $down entier qui permet de spécifier la profondeur des membres descendant attendus dans la réponse d'API
: @see https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html
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
: Cette fonction gère le endpoint Document. Elle permet de renvoyer un document ou un fragment du document XML identifié par le paramètre $id
: @return réponse XML-TEI pour les endpoints Document de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier le document XML (obligatoire)
: @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
: @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
: @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
: @param $format chaîne de caractère pour spécifier le format de sortie attendu. Les formats possibles sont: XML (par défaut), html et txt.
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
      let $doc := 
        if (db:get($project)/tei:TEI[@xml:id = $id])
        then db:get($project)/tei:TEI[@xml:id = $id]
        else 
          db:get($project, $id)/tei:TEI
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





