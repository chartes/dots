xquery version "3.1";

(:~  
: Ce module permet d'initialiser la base de données "dots" et y ajoute les deux documents XML: "dots_db_switcher.xml" et "dots_default_metadata_mapping.xml".
: "dots_db_switcher.xml" permet:
: - de recenser toutes les ressources disponibles
: - de préciser le type de ressource ('project' pour une collection de niveau 1, 'collection' ou 'document') 
: - d'indiquer pour chaque ressource son identifiant (@dtsResourceId)
: - et d'indiquer le nom de la db BaseX à laquelle appartient la ressource (@dbName)
: Ce document lors de son initialisation, ne liste aucune ressource. Cette étape est opérée ultérieurement.
: Ces informations servent au routeur DTS pour savoir pour chaque ressource dans quelle db trouver les registres DoTS qui la concerne.
: "dots_default_metadata_mapping.xml" est un document pour déclarer par défaut des métadonnées de description des documents.
: Il n'est utilisé que si aucun autre document "metadata_mapping" n'est disponible
: @author École nationale des chartes
: @since 2023-06-14
: @version  1.0
:)

module namespace dots.lib = "https://github.com/chartes/dots/lib"; 

import module namespace functx = 'http://www.functx.com';

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";

(:~ 
: Cette fonction permet d'ajouter ou modifier les deux documents XML de la db dots.
: @return 2 documents XML à ajouter à la db "dots"
: @param $G:dots chaîne de caractère, variable globale pour accéder à la db dots
: @param $dbName chaîne de caractère qui donne le nom de la db
: @param $topCollectionId chaîne de caractère correspondant à l'identifiant du projet (qui peut être différent du nom de la db)
: @see db_switch_builder.xqm;db.switcher:getTopCollection
: @see db_switch_builder.xqm;db.switcher:members
: @see db_switch_builder.xqm;db.switcher:getHeaders
:)
declare updating function dots.lib:dots_db_init() {
  let $dbSwitch := dots.lib:switcher_init()
  let $metadataMap := dots.lib:metadataMap_init()
  return
    db:create($G:dots, ($dbSwitch, $metadataMap), ($G:dbSwitcher, $G:metadataMapping))
};

(:~ 
: Cette fonction prépare l'en-tête des deux documents XML à créer pour la db dots
: @return élément XML <metadata></metadata> avec son contenu
: @param $option chaîne de caractère pour savoir si l'élément <totalProject/> doit être intégré au header
:)
declare function dots.lib:getHeaders($option as xs:string) {
  <metadata>
    <dct:created>{current-dateTime()}</dct:created>
    <dct:modified>{current-dateTime()}</dct:modified>
    {if ($option = "dbSwitch") then <totalProjects>0</totalProjects> else ()}  
  </metadata>
};

declare function dots.lib:switcher_init() {
  <dbSwitch xmlns="https://github.com/chartes/dots/">{
    dots.lib:getHeaders("dbSwitch"),
    <member/>
  }</dbSwitch>
};

declare function dots.lib:metadataMap_init() {
  <metadataMap xmlns="https://github.com/chartes/dots/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dct="http://purl.org/dc/terms/">{
    dots.lib:getHeaders("metadataMap"),
    <mapping>
      <dc:title xpath="//titleStmt/title[@type = 'main' or position() = 1]" scope="document"/>
      <dc:creator xpath="//titleStmt/author" scope="document"/>
      <dct:publisher xpath="//publicationStmt/publisher" scope="document"/>
    </mapping>
  }</metadataMap>
};







