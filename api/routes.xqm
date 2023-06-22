xquery version "3.1";

(:~ 
: Ce module regroupe les urls à servir pour la mise en oeuvre de l'API DTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-05-15
: @version  1.0
: @todo Revoir en profondeur les namespaces
:)

module namespace routes="https://github.com/chartes/dots/api/routes";

import module namespace utils = "https://github.com/chartes/dots/api/utils" at "utils.xqm";

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
function routes:collections($id as xs:string) {
  if ($id)
  then
    utils:collectionById($id)
   else
     utils:collections()
};

(:~ 
: Cette fonction permet de renvoyer un document ou un fragment du document XML identifié par le paramètre $id
: @return réponse XML-TEI pour les endpoints Document de la spécification d'API DTS
: @param $id chaîne de caractère qui permet d'identifier le document XML (obligatoire)
: @see https://distributed-text-services.github.io/specifications/Documents-Endpoint.html
: @todo $ref, $start, $end, etc. (paramètre facultatif pour servir un fragment de XML)
:)
declare
  %rest:path("/api/dts/document")
  %rest:GET
  %output:method("xml")
  %rest:produces("application/tei+xml")
  %rest:query-param("id", "{$id}", "")
function routes:document($id as xs:string) {
  utils:document($id)
};







