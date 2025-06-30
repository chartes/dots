xquery version "4.0";

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
(:~
 : Module to initialize the "dots" database with two XML documents:
 : "dots_db_switcher.xml": lists available resources and specifies:
 :  - the resource type ("project", "collection", or "document"),
 :  - its unique identifier (@dtsResourceId),
 :  - and the corresponding BaseX database (@dbName).
 : Initially empty, this file is later populated with resource entries.
 : It is used by the DTS router to locate metadata for each resource.
 :
 : "dots_default_metadata_mapping.xml": default metadata mapping applied when no custom mapping is available. It extracts key metadata (title, creator, publisher) using XPath expressions.
 :
 : Author: École nationale des chartes  
 : Since: 2023-06-14  
 : Version: 1.0
:)
module namespace dots.build = "backend/db_switch_build";

import module namespace G = "globals";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace dct = "http://purl.org/dc/terms/";

(:~
 : Creates or updates the two XML documents in the "dots" database.
 : @return  The two documents to be added to the "dots" database.
:)
declare updating function dots.build:dots_db() {
  let $dbSwitch := dots.build:switcher()
  let $metadataMap := dots.build:metadataMap()
  return db:create($G:dots, ($dbSwitch, $metadataMap), ($G:dbSwitcher, $G:metadataMapping))
};

(:~
: Generates the <metadata> header for each XML document.
: @param   $option a string flag to indicate if the <totalProjects/> tag should be added.
: @return  a <metadata> element with creation and modification timestamps.
:)
declare %private function dots.build:headers($option as xs:string) {
  <metadata>
    <dct:created>{ current-dateTime() }</dct:created>
    <dct:modified>{ current-dateTime() }</dct:modified>
    { if ($option = "dbSwitch") then <totalProjects>0</totalProjects> }
  </metadata>
};

(:~
: Creates the initial, "dots_db_switcher.xml" document.
: @return a <dbSwitch/> element, with <metadata/> and empty <member/> childs.
:)
declare %private function dots.build:switcher() {
  <dbSwitch xmlns="https://github.com/chartes/dots/">{
    dots.build:headers("dbSwitch"),
    <member/>
  }</dbSwitch>
};

(:~
 : Creates the "dots_default_metadata_mapping.xml" document.
 : @return a <metadataMap/> element with XPath-based mappings for title, creator, and publisher metadata.
:)
declare %private function dots.build:metadataMap() {
  <metadataMap xmlns="https://github.com/chartes/dots/" xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:dct="http://purl.org/dc/terms/">{
    dots.build:headers("metadataMap"),
    <mapping>
      <dc:title xpath="//titleStmt/title[@type = 'main' or position() = 1]" scope="document"/>
      <dc:creator xpath="//titleStmt/author" scope="document"/>
      <dct:publisher xpath="//publicationStmt/publisher" scope="document"/>
    </mapping>
  }</metadataMap>
};
