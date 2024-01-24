xquery version "3.1";

(:~  
: Ce module permet de créer dans la base de données "dots" les documents XML "dots_db_switcher.xml" et "dots_default_metadata_mapping.xml".
: "dots_db_switcher.xml" permet:
: - de recenser toutes les ressources disponibles
: - de préciser le type de ressource ('project' pour une collection de niveau 1, 'collection' ou 'document') 
: - et d'indiquer le nom de la db BaseX à laquelle appartient la ressource
: Ces informations servent au routeur DTS pour savoir pour chaque ressource où trouver les registres DoTS qui la concerne.
: "dots_default_metadata_mapping.xml" est un document pour déclarer par défaut des métadonnées de description des documents.
: Il n'est utilisé que si aucun autre document "metadata_mapping" n'est disponible
: @author École nationale des chartes - Philippe Pons
: @since 2023-06-14
: @version  1.0
:)

module namespace ccg = "https://github.com/chartes/dots/builder/ccg"; (: changer ccg par "sw"? "switcher"? :)

import module namespace functx = 'http://www.functx.com';

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace cc = "https://github.com/chartes/dots/builder/cc" at "resources_register_builder.xqm";
import module namespace var = "https://github.com/chartes/dots/variables" at "../project_variables.xqm";

declare default element namespace "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";

(:~ 
: Cette fonction permet d'ajouter ou modifier les deux documents XML à la db dots.
: @return 2 documents XML à ajouter à la db "dots"
: @param $G:dots chaîne de caractère variable globale pour accéder à la db dots
: @param $var:idProject chaîne de caractère correspondant à l'identifiant du projet (qui peut être différent du nom de la db)
: @todo $var:dbName ou plutôt $dbName (variable externe): plutôt la seconde solution
: @todo changer le nom de la fonction! "switcher:createSwitcherDoc"?
:
:)
declare updating function ccg:create_config() {
  if (db:exists($G:dots))
  then 
    if (db:get($G:dots)//project[@dbName = $var:dbName])
    then ()
    else
      let $dots := db:get($G:dots)/dbSwitch
      let $totalProject := $dots//totalProjects
      let $modified := $dots//dct:modified
      let $member := $dots//member
      let $contentMember :=
        (
          ccg:getProject($var:idProject, $var:dbName),
          ccg:members($var:dbName, "")
        )
      return
        (
          replace value of node $modified with current-dateTime(),
          replace value of node $totalProject with xs:integer($totalProject) + 1,
          insert node $contentMember as last into $member
        )
  else
    let $dbSwitch :=
      <dbSwitch 
        xmlns="https://github.com/chartes/dots/" 
        xmlns:dct="http://purl.org/dc/terms/">
        {ccg:getMetadata("dbSwitch")}
        <member>{
          ccg:getProject($var:idProject, $var:dbName),
          ccg:members($var:dbName, "")
        }</member>
      </dbSwitch>
    let $metadataMap :=
      <metadataMap 
        xmlns="https://github.com/chartes/dots/" 
        xmlns:dct="http://purl.org/dc/terms/">
        {ccg:getMetadata("metadataMap")}
        <mapping>
          <dc:title xpath="//titleStmt/title[@type = 'main' or position() = 1]" scope="document"/>
          <dc:creator xpath="//titleStmt/author" scope="document"/>
          <dct:publisher xpath="//publicationStmt/publisher" scope="document"/>
        </mapping>
      </metadataMap>
    return
      let $validate := validate:rng-info($dbSwitch, $G:dbSwitchValidation)
      return
        (
          db:create($G:dots, ($dbSwitch, $metadataMap), ($G:dbSwitcher, $G:metadataMapping))
        )
};

(:~ 
: Cette fonction se contente de construire l'en-tête <configMetadata/> du fichier de configuration
:)
declare function ccg:getMetadata($option as xs:string) {
  <metadata>
    <dct:created>{current-dateTime()}</dct:created>
    <dct:modified>{current-dateTime()}</dct:modified>
    {if ($option = "dbSwitch") then <totalProjects>1</totalProjects> else ()}  
  </metadata>
};

declare function ccg:getProject($idProject as xs:string, $dbName as xs:string) {
  <project dtsResourceId="{$idProject}" dbName="{$dbName}"/>
};

declare function ccg:members($dbName as xs:string, $path as xs:string) {
  for $dir in db:dir($dbName, $path)
  where not(contains($dir, $G:metadata))
  return
    if ($dir/name() = "resource")
    then ccg:resource($dbName, $dir, $path)
    else
      if ($dir != "")
      then
      (
        ccg:collection($dbName, $dir, $path), 
        ccg:members($dbName, concat($path, "/", $dir))
      ) else ()
};

declare function ccg:resource($dbName as xs:string, $fileNameResource as xs:string, $pathResource as xs:string) {
  let $doc := db:get($dbName, concat($pathResource, "/", $fileNameResource))/tei:TEI
  let $id := if ($doc/@xml:id) then normalize-space($doc/@xml:id) else functx:substring-after-last(db:path($doc), "/")
  return
    if ($doc)
    then
      <document dtsResourceId="{$id}" dbName="{$dbName}"/>
    else ()
};

declare function ccg:collection($dbName as xs:string, $collection as xs:string, $path as xs:string) {
  let $totalItems := count(db:dir($dbName, $collection))
  let $parent := if ($path = "") then $dbName else $path
  return
    if ($collection = "dots") then () else <collection dtsResourceId="{$collection}" dbName="{$dbName}"/>
};







