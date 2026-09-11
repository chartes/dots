xquery version "3.1";


(:~ 
: Ce module regroupe les urls à servir pour la mise en oeuvre de l'API DTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
:)
module namespace routes="https://github.com/dots-suite/dotsapi/routes";

import module namespace cache = 'cache';
import module namespace G = "globals";
import module namespace utils = "resolver/utils";
import module namespace http_error = "error/http_error"; 

declare namespace dots = "https://github.com/dots-suite/dots";
declare namespace dts = "https://w3id.org/dts/api#";

(:~  
: Cette fonction gère le point d'entrée de l'API DTS
: @return réponse JSON pour le endpoint EntryPoint
: @see https://distributed-text-services.github.io/specifications/Entry.html#base-api-endpoint
:)
declare
  %rest:path("/api/dts")
  %rest:GET
  %output:encoding("UTF-8")
  %output:method("json")
  %output:media-type("application/ld+json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
function routes:entryPoint() {
  let $base-uri := substring-before(request:uri(), "/api")
  return
  <json type="object">    
    <pair name="@context">https://dtsapi.org/context/v1.0.json</pair>
    <pair name="dtsVersion">1.0</pair>
    <pair name="@id">/api/dts</pair>
    <pair name="@type">EntryPoint</pair>
    <pair name="collection">{ concat($base-uri, "/api/dts/collection/{?id,nav}") }</pair>
    <pair name="navigation">{ concat($base-uri, "/api/dts/navigation/{?resource,ref,start,end,down,tree}") }</pair>
    <pair name="document">{ concat($base-uri, "/api/dts/document/{?resource,ref,start,end,tree,mediaType}") }</pair>
  </json>
};

(:~  
 : Cette fonction gère le endpoint Collection. Elle dispatche vers les fonctions permettant de donner
 : les informations concernants la/les collection(s) DTS existante(s) si le paramètre $id n'est pas
 : précisé. Sinon, les informations concernant la collection DTS identifiée par le paramètre $id
 : @param $id chaîne de caractère qui permet d'identifier une collection DTS
 : @param $nav chaîne de caractère dont la valeur est children (par défaut) ou parents.
 :   Ce paramètre permet de définir si les membres à lister sont les enfants ou les parents
 : @param  $filter .
 : @return réponse JSON pour le endpoints Collection de la spécification d'API DTS
 : @see https://distributed-text-services.github.io/specifications/Collections-Endpoint.html
 : @see utils.xqm;utils:collectionById
 : @see utils.xqm;utils:collections
 :) 
declare
  %rest:path("/api/dts/collection")
  %rest:GET
  %output:encoding("UTF-8")
  %output:method("json")
  %output:media-type("application/ld+json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("id", "{$id}", "")
  %rest:query-param("nav", "{$nav}", "")
  %rest:query-param("filter", "{$filter}")
function routes:collections(
  $id as xs:string,
  $nav as xs:string,
  $filter
) {
  if (db:exists($G:dots))
  then 
    if ($id)
    then
      if (db:get($G:dots)/dots:metadataMap/dots:root/dots:id = $id)
      then utils:collections()
      else
      let $dbName := normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $id]/@dbName)
      let $code := fn() {
        if ($dbName != "") 
        then 
          utils:collectionById($id, $nav, $filter)
        else
          http_error:badIdResource(xs:string($id))
  }
      let $key := request:query()
      return cache:cache($dbName, $id, $key, $code)
    else
      utils:collections()
  else
    utils:noCollection()
};

(:~  
 : Cette fonction gère le endpoint Navigation. Elle dispatche vers les fonctions permettant de donner
 : les informations du endpoint Navigation pour la collection $id
 : @param $resource .
 : @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
 : @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
 : @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
 : @param $tree .
 : @param $filter .
 : @param $down entier qui permet de spécifier la profondeur des membres descendant attendus dans la réponse d'API
 : (@param $id chaîne de caractère qui permet d'identifier une collection DTS)
 : @return réponse JSON pour le endpoint Navigation de la spécification d'API DTS
 : @see https://distributed-text-services.github.io/specifications/Navigation-Endpoint.html
 : @todo revoir la gestion des erreurs HTTP 4XX. Particulièrement après avoir mieux intégré le param 'tree'
 :)
declare
  %rest:path("/api/dts/navigation")
  %rest:GET
  %output:encoding("UTF-8")
  %output:method("json")
  %output:media-type("application/ld+json")
  %rest:produces("application/ld+json")
  %output:json("format=attributes")
  %rest:query-param("resource", "{$resource}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("tree", "{$tree}", "")
  %rest:query-param("down", "{$down}", "-2")
  %rest:query-param("filter", "{$filter}", "")
function routes:navigation(
  $resource as xs:string,
  $ref as xs:string,
  $start as xs:string,
  $end as xs:string,
  $tree as xs:string,
  $filter,
  $down as xs:integer
) {
  if (not($resource) or ($ref and ($start or $end)) or ($start and not($end)) or ($end and not($start)) )
  then
    let $message := "Error 400 : Bad request"
    return
      web:error(400, $message)
  else
    let $dbName := normalize-space(db:get($G:dots)//dots:member/node()[@dtsResourceId = $resource]/@dbName)
    let $code := fn() {
      if ($dbName != "") 
      then 
        if($down != -2)
        then
          utils:navigation($resource, $ref, $start, $end, $tree, $filter, $down) 
        else
          let $query := request:query()
          return
            if (contains($query, "ref=") or contains($query, "start=") or contains($query, "filter="))
            then
              utils:navigation($resource, $ref, $start, $end, $tree, $filter, $down) 
            else
              web:redirect(concat("/api/dts/navigation?", request:query(), "&amp;down=1"))
      else
        http_error:badIdResource(xs:string($resource))    
}
    let $key := request:query()
    return cache:cache($dbName, $resource, replace($key, '\W', '_'), $code)
};

(:~ 
 : Cette fonction gère le endpoint Document. Elle permet de renvoyer un document ou un fragment du
 : document XML identifié par le paramètre $id
 : @param $resource .
 : @param $ref chaîne de caractère qui permet d'identifier un élément citable dans le document
 : @param $start chaîne de caractère. Identifiant du premier élément d'une séquence
 : @param $end chaîne de caractère. Identifiant du dernier élément d'une séquence 
 : @param $tree .
 : @param $mediaType .
 : @param $filter .
 : @param $excludeFragments .
 : (@param $id chaîne de caractère qui permet d'identifier le document XML (obligatoire))
 : (@param $format chaîne de caractère pour spécifier le format de sortie attendu.
    Les formats possibles sont: XML (par défaut), html et txt.)
 : @return réponse XML-TEI pour les endpoints Document de la spécification d'API DTS
 : @see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
 :)
declare
  %rest:path("/api/dts/document")
  %rest:GET
  %rest:query-param("resource", "{$resource}", "")
  %rest:query-param("ref", "{$ref}", "")
  %rest:query-param("start", "{$start}", "")
  %rest:query-param("end", "{$end}", "")
  %rest:query-param("tree", "{$tree}", "")
  %rest:query-param("mediaType", "{$media-type}", "application/tei+xml")
  %rest:query-param("filter", "{$filter}", "")
  %rest:query-param("excludeFragments", "{$excludeFragments}", false())
  %rest:query-param("renderer", "{$renderer}", "")
function routes:document(
  $resource as xs:string,
  $ref as xs:string,
  $start as xs:string,
  $end as xs:string,
  $tree as xs:string,
  $media-type as xs:string,
  $filter,
  $excludeFragments as xs:boolean,
  $renderer as xs:string
) {
  if (not($resource) or ($ref and ($start or $end)) or ($start and not($end)) or ($end and not($start)) or ($filter and $excludeFragments) )
  then
    let $message := "Error 400 : Bad request"
    return
      web:error(400, $message)
  else
    let $dbName := db:get($G:dots)//dots:member/node()[@dtsResourceId = $resource]/@dbName
    return
      if ($dbName) 
      then 
        let $result := utils:document($resource, $ref, $start, $end, $tree, $filter, $excludeFragments)
        return
          let $f :=
            switch ($media-type)
            case ($media-type[contains(., "tei")]) return xs:string("application/xml")
            case ($media-type[. = "xml"]) return xs:string("application/xml")
            case ($media-type[. = "html"]) return xs:string("text/html")
            case ($media-type[. = "txt"]) return xs:string("text/plain")
            default return http_error:errorNotFound("Error 404: requested media type is not available")
          let $serialisation := 
            switch ($media-type)
            case ($media-type[. = "txt"]) return routes:renderer-serialize($dbName, $resource, $result, $media-type, $renderer)
            case ($media-type[. = "html"]) return 
              if ($renderer) 
              then routes:renderer-serialize($dbName, $resource, $result, $media-type, $renderer) 
              else routes:transform-serialize($dbName, $resource, $result)
            default return 
              routes:tei-serialize($result, $renderer)
            
         return
            (
              <rest:response>
                <http:response status="200">
                  <http:header name="Content-Type" value="{concat($f, ' charset=utf-8')}"/>
                  {if ($media-type = 'application/tei+xml') then <http:header name="Accept" value="application/tei+xml"/>}
                </http:response>
              </rest:response>,
              $serialisation
            ) 
      else
        http_error:badIdResource(xs:string($resource))
};

(:~ 
 : Cette fonction sérialise un document TEI en XML, en y injectant éventuellement une
 : processing-instruction xml-stylesheet pointant vers la CSS d'un renderer TEI nommé.
 : Si aucun renderer n'est fourni, le document est sérialisé tel quel, sans feuille de style associée.
 : @param $content séquence de nœuds XML-TEI à sérialiser.
 : @param $renderer chaîne de caractère identifiant un scénario de rendu TEI déclaré dans
    renderer_config.xml (facultatif). Si absent, aucune CSS n'est associée au document.
 : @return réponse XML-TEI sérialisée, précédée d'une processing-instruction xml-stylesheet
    si $renderer est fourni et résolu avec succès ; erreur 404 si $renderer est fourni mais
    qu'aucun renderer TEI correspondant n'est déclaré dans la configuration.
 :)
declare function routes:tei-serialize(
  $content,
  $renderer as xs:string := ()) {
  if (not($renderer))
  then serialize($content, map { "method": "xml" })
  else
    let $pathRenderer := G:linkToRenderer()
    let $config := doc(concat($pathRenderer, "renderer_config.xml"))
    let $findPath :=
      $config/dots:renderers/dots:renderer[@mediaType = "tei" and @name = $renderer]/@path
    return
      if (not($findPath))
      then
        let $message := concat("Error 404: tei rendering is not available for scenario '", $renderer, "'")
        return http_error:errorNotFound($message)
      else
        let $fullPath := concat($G:base_uri, "/static/renderers/", $renderer, "/", $findPath)
        return (
          processing-instruction xml-stylesheet {
            concat('type="text/css" href="', $fullPath, '"')
          },
          serialize($content, map { "method": "xml" })
        )
};

(:~ 
 : Cette fonction gère la transformation HTML d'une ressource en donnant priorité aux
 : personnalisations XSL de transform/ (spécifique au document, puis au projet/base) avant
 : de retomber sur le mécanisme générique des renderers si aucune personnalisation n'existe.
 : Le résultat est mis en cache.
 : @param $dbName chaîne de caractère identifiant la base de données (projet) concernée.
 : @param $resource chaîne de caractère identifiant la ressource (document) à transformer.
 : @param $result séquence de nœuds XML à transformer et sérialiser en HTML.
 : @return réponse HTML sérialisée, produite soit via la XSL de personnalisation
    (documentId.xsl ou dbName.xsl dans transform/) si elle existe, soit via le renderer HTML
    par défaut résolu par routes:renderer-serialize dans le cas contraire.
 :)
declare function routes:transform-serialize($dbName, $resource, $result) {
  let $xsl := G:linkToTransform()
  let $style :=
      if (file:exists(concat($xsl, $dbName, "/", $resource, ".xsl")))
      then concat($xsl, $dbName, "/", $resource, ".xsl")
      else 
        if (file:exists(concat($xsl, $dbName, "/", $dbName, ".xsl")))
        then concat($xsl, $dbName, "/", $dbName, ".xsl")
        else ()
  return
    let $code := fn() {
      if ($style)
      then 
        let $staticPath := environment-variable("static_path")
        return
          xslt:transform($result, $style, map { "static_path": $staticPath })
          => serialize(map {"method": "html"})
      else routes:renderer-serialize($dbName, $resource, $result, "html")
    }
    let $key := request:query()
    return cache:cache($dbName, $resource, $key, $code)
};

(:~ 
 : Cette fonction sérialise une ressource dans le format demandé (html ou txt) en utilisant le
 : renderer explicitement nommé s'il est fourni, ou le renderer par défaut du format sinon. Le
 : chemin du renderer et sa feuille de transformation associée sont résolus via renderer_config.xml.
 : Le résultat est mis en cache.
 : @param $dbName chaîne de caractère identifiant la base de données (projet) concernée.
 : @param $resource chaîne de caractère identifiant la ressource (document) à transformer.
 : @param $content séquence de nœuds XML à transformer et sérialiser.
 : @param $format chaîne de caractère spécifiant le format de sortie attendu (html ou txt).
 : @param $renderer chaîne de caractère identifiant un scénario de rendu déclaré dans
    renderer_config.xml (facultatif). Si absent ou vide, le renderer par défaut du format est utilisé.
 : @return réponse sérialisée (HTML ou texte) produite par le renderer résolu ; erreur 404 si le
    format demandé n'est pas disponible (pour le renderer nommé, le cas échéant).
 :)
declare function routes:renderer-serialize(
  $dbName,
  $resource,
  $content,
  $format as xs:string,
  $renderer as xs:string := ""
) {
  let $key := request:query()
  let $code := fn() {
    let $pathRenderer := G:linkToRenderer()
    let $configPath := concat($pathRenderer, "renderer_config.xml")
    return
      if (not(file:exists($configPath)))
      then http_error:errorInternalServerError(
        "Error 500: renderer_config.xml not found — did you rename renderer_config_template.xml to renderer_config.xml?"
      )
      else
        let $config := doc(concat($pathRenderer, "renderer_config.xml"))
        let $rendererNode := (
          $config/dots:renderers/dots:renderer[@mediaType = $format][
            if ($renderer) then @name = $renderer else @default
          ]
        )[1]
        return
          if (not($rendererNode))
          then
            if ($renderer)
            then
              http_error:errorNotFound(
                concat("Error 404: ", $format, " output format is not available for scenario '", $renderer, "'")
              )
            else
              http_error:errorInternalServerError(
                concat("Error 500: no default renderer configured for the '", $format, "' format")
              )
          else           
            let $staticPath := environment-variable("static_path")
            let $htmlTransform := function($content, $fullPath) {
              xslt:transform($content, $fullPath, map { "static_path": $staticPath })
            }
            let $transformFunctions := map {
              "html": $htmlTransform,
              "txt": xslt:transform-text#2
            }
            let $serializeMethods := map { "html": "html", "txt": "text" }
            let $transformFunction := $transformFunctions($format)
            let $serializeMethod := $serializeMethods($format)
            let $fullPath := concat($pathRenderer, $rendererNode/@name, "/", $rendererNode/@path)
            return
              try {
                $transformFunction($content, $fullPath)
                => serialize(map { "method": $serializeMethod })
              } catch * {
                let $message :=
                  if ($renderer)
                  then concat("Error 404: ", $format, " output format is not available for scenario '", $renderer, "'")
                  else concat("Error 404: ", $format, " output format is not available")
                return http_error:errorNotFound($message)
              }
      }
  return cache:cache($dbName, $resource, $key, $code)
};


