xquery version '3.0' ;

module namespace G = 'globals';
(:~
: Ce module regroupe les variables globales de DoTS
: @version 1
: @date 2023-07-06 
: @author École nationale des chartes - Philippe Pons
:)

declare default element namespace "https://github.com/dots-suite/dots";

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Variables pour le resolver 
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :) 

declare variable $G:base_uri :=
  if (environment-variable("base_uri"))
  then environment-variable("base_uri")
  else substring-before(request:uri(), "/api");

(:~ Variable pour accéder aux feuilles de transformation XSLT :)
declare function G:linkToRenderer() {
  concat($G:webapp, "webapp/static/renderers/")
};

declare function G:linkToTransform() {
  let $specificLink := db:get($G:dots)//settings/linkXSL
  return
    if ($specificLink != "")
    then if (ends-with($specificLink, "/")) then $specificLink else concat($specificLink, "/")
    else 
      if (environment-variable("transform_path"))
      then environment-variable("transform_path")
      else concat($G:webapp, "webapp/static/transform/")
};

declare function G:defaultXslEnginePath() {
  let $defaultEngine := db:get($G:dots)//settings/defaultEngine
  return
    if ($defaultEngine != "") 
    then normalize-space($defaultEngine) 
    else 
      if (environment-variable("xsl_path"))
      then environment-variable("xsl_path")
      else concat(G:linkToRenderer(), "html/teic/teic.xsl")
};
(: "hteiml/tei2html.xsl" :)

(: declare variable $G:defaultXslEnginePath := "hteiml/tei2html.xsl"; :)

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Variables pour le DoTS Project Manager 
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :) 

declare variable $G:dbSwitcher := "dots_db_switcher.xml";

declare variable $G:metadataMapping := "dots_default_metadata_mapping.xml";

(: Variable pour déclarer le séparateur utilisé pour les documents CSV. Attention: un seul séparateur possible commun à tous les documents CSV :)
declare variable $G:separator := "	";

(: Code langue de la langue principale du corpus pour indexation
: @todo: à conserver? utile?
: @todo: le rendre facultatif
:)
declare variable $G:language := "fr";




(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
      Variables "transverses" 
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :) 

(:~ Variable pour accéder au nom de la base de données dots :)
declare variable $G:dots := "dots";

declare variable $G:metadata := "metadata/";

(:~ Variable pour accéder au document "resources_register.xml" d'un projet :)
declare variable $G:resourcesRegister := "dots/resources_register.xml";

(:~ Variable pour accéder au registre (documentRegister)  qui liste les passages citables:)
declare variable $G:fragmentsRegister := "dots/fragments_register.xml";

(:~ This function allows retrieving the identifier ('topCollectionId') of a database based on its name.
: @param $dbName name of the database
: @return a string (identifier of a project)
:)
declare function G:getTopCollectionId($dbName as xs:string) {
  normalize-space(db:get($dbName, $G:resourcesRegister)//collection[not(@parentIds)]/@dtsResourceId)
};





(: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
    Variables pour le module Validate (à reprendre)
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ :) 
   
declare variable $G:dbSwitchValidation := concat($G:webapp, "/schema/dots_db_switcher.rng");

declare variable $G:resourcesValidation := concat($G:webapp, "/schema/resources_register.rng");

declare variable $G:fragmentsValidation := concat($G:webapp, "/schema/fragments_register.rng");


(:~ Variable pour accéder au webapp :)
declare variable $G:webapp := file:parent(file:base-dir());
