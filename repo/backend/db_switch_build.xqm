xquery version "4.0";

(:~
: Module to initialize the "dots" database with two XML documents:
: "dots_db_switcher.xml": lists available resources and specifies:
:  - the resource type ("project", "collection", or "document"),
:  - its unique identifier (@dtsResourceId),
:  - and the corresponding BaseX database (@dbName).
: Initially empty, this file is later populated with resource entries.
: It is used by the DTS router to locate metadata for each resource.
: "dots_default_metadata_mapping.xml": default metadata mapping applied when no custom mapping is available. It extracts key metadata (title, creator, publisher) using XPath expressions.
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
declare updating function dots.build:dots_db($rootId := "", $rootTitle := "", $rootDescription := "", $linkXSL := "", $defaultEngine := "") {
  let $dbSwitch := dots.build:switcher()
  let $metadataMap := dots.build:metadataMap($rootId, $rootTitle, $rootDescription, $linkXSL, $defaultEngine)
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
 : @todo vérifier que cette fonction fonctionne correctement. Et comment gérer l'ajout d'un nouveau projet ? Comment faire un update de ces paramètres ?
:)
declare %private function dots.build:metadataMap($rootId as xs:string := "", $rootTitle as xs:string := "", $rootDescription as xs:string := "", $linkXSL as xs:string := "", $defaultEngine as xs:string := "") {
  <metadataMap xmlns="https://github.com/chartes/dots/" xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:dct="http://purl.org/dc/terms/">{
    dots.build:headers("metadataMap"),
    <root>
      <id>{if ($rootId != "") then $rootId else "default"}</id>
      <title>{if ($rootTitle != "") then $rootTitle else "default title"}</title>
      {if ($rootDescription != "") then <description>{$rootDescription}</description>}
    </root>,
    <mapping>      
      <dct:title xpath="//titleStmt/title[@type = 'main' or position() = 1]" scope="document"/>
      <dct:creator xpath="//titleStmt/author" scope="document"/>
      <dct:publisher xpath="//publicationStmt/publisher" scope="document"/>
    </mapping>,
    <settings>
      <linkXSL>{$linkXSL}</linkXSL>
      <defaultEngine>{$defaultEngine}</defaultEngine>
    </settings>
  }</metadataMap>
};
