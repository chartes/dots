(:~
 : This module contains some basic examples for RESTXQ annotations.
 : @author BaseX Team
 :)
module namespace page = 'http://basex.org/examples/web-page';

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace cc = "https://github.com/chartes/dots/schema/utils/cc" at "../schema/utils/project.xqm";
import module namespace cc2 = "https://github.com/chartes/dots/schema/utils/cc2" at "../schema/utils/project_metadata.xqm";

import module namespace functx = "http://www.functx.com";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace html = "http://www.w3.org/1999/xhtml";

(:~
 : Generates a welcome page.
 : @return HTML page
 :)
declare
  %rest:GET
  %rest:path('dots')
  %output:method('xhtml')
  %output:omit-xml-declaration('no')
  %output:doctype-public('-//W3C//DTD XHTML 1.0 Transitional//EN')
  %output:doctype-system('http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd')
function page:start(
) as element(Q{http://www.w3.org/1999/xhtml}html) {
  <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <title>Routeur DoTS - Implémentation de l'API DTS pour BaseX</title>
      <link rel='stylesheet' type='text/css' href='/static/style.css'/>
    </head>
    <body>
      <div class='right'><a href='/dots'><img src='/static/dots-logo.png'/></a></div>
      <h1>Routeur DoTS - Implémentation de l'API DTS pour BaseX</h1>
      <div>
      <ul>
        <li><a href="/dots/configuration">Créer un fichier de configuration pour une collection DTS</a></li>
      </ul>
      </div>
    </body>
  </html>
};

declare
  %rest:GET
  %rest:path('/dots/configuration')
  %output:method('xhtml')
  %rest:query-param("csv", "{$csv}")
  %rest:query-param("bdd", "{$bdd}")
  %rest:query-param("check", "{$check}")
  %output:omit-xml-declaration('no')
  %output:doctype-public('-//W3C//DTD XHTML 1.0 Transitional//EN')
  %output:doctype-system('http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd')
function page:configuration($csv, $bdd, $check) as element(Q{http://www.w3.org/1999/xhtml}html) {
  <html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
      <title>DoTS - Configuration</title>
      <link rel='stylesheet' type='text/css' href='/static/style.css'/>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.0/jquery.min.js"></script>
      <script type="text/javascript" src="/static/test.js"></script>
    </head>
    <body>
      <div class='right'><a href='/dots'><img src='/static/dots-logo.png'/></a></div>
      <h1>Routeur DoTS - Configuration</h1>
      <div>
        <div>
          <h2>Step 1. Database information</h2>
          <p>
            <div id="checkForm">
              <label>Database name </label><input id="bddInput" name="bdd"/><br/>
              <button id="check">Check DB</button>
            </div>
          </p>
          <p id="check_response"></p>
        </div>
        <hr/>
        <div>
          <h2>Step 2. Title of the database</h2>
          <p>
            <label>Title database </label><input id="bddTitle" name="title"/><br/>
          </p>
        </div><hr/>
        <div>
          <h2>Step 3. Configuration.xml and declaration.xml creation</h2>
          <form action="/upload" method="POST" name="upload" enctype="multipart/form-data">
            <label>Nom de la bdd: </label><input name="bdd2"/><br/>
            <input id="file" type="file" name="file"/><br/>
            <input name="boolean" type="checkbox"/><label>Do you want to add TEI metadata?</label><br/>
            <button id="generate">Generate sheet</button>
          </form>
        </div>
        {
          if ($csv)
          then 
            <div>
              <div id="table"><table>
                <tr>
                  <th>Input</th>
                  <th>Namespace</th>
                  <th>Output</th>
                  <th>Prefix</th>
                  <th>Suffix</th>
                  <th>XPath</th>
                  <th>Keep it?</th>
                </tr>
                {
                  for $record at $pos in db:get($bdd, $G:metadata)//*:record/node()
                  let $name := $record/name()
                  group by $name
                  return
                    <tr>
                      <td>{$name}</td>
                      <td><input id="{concat('namespace_', $name)}" type="text" name="{concat('namespace_', $name)}"/></td>
                      <td><input id="{concat('output_', $name)}" type="text" name="{concat('output_', $name)}"/></td>
                      <td><input id="{concat('prefix_', $name)}" type="text" name="{concat('prefix_', $name)}"/></td>
                      <td><input id="{concat('suffix_', $name)}" type="text" name="{concat('suffix_', $name)}"/></td>
                      <td></td>
                      <td><input id="{concat('keep_', $name)}" type="checkbox" name="{concat('keep_', $name)}"/></td>
                    </tr>
                }
                {
                  if ($check != "")
                  then
                    for $metaTEI in db:get($bdd)//tei:TEI/tei:teiHeader//node()
                    let $name := $metaTEI/name()
                    where $metaTEI//text() != "" and $name != ""
                    group by $name
                    order by $name
                    return
                      <tr>
                        <td>{$name}</td>
                        <td><input id="{concat('namespace_', $name)}" type="text" name="{concat('namespace_', $name)}" value="http://www.tei-c.org/ns/1.0"/></td>
                        <td><input id="{concat('output_', $name)}" type="text" name="{concat('output_', $name)}"/></td>
                        <td><input id="{concat('prefix_', $name)}" type="text" name="{concat('prefix_', $name)}"/></td>
                        <td><input id="{concat('suffix_', $name)}" type="text" name="{concat('suffix_', $name)}"/></td>
                        <td><input id="{concat('xpath_', $name)}" type="text" name="{concat('xpath_', $name)}">{
                          let $value :=
                            for $node in functx:path-to-node($metaTEI)
                            group by $node
                            return
                              concat("/", $node)
                          return
                            attribute {"value"} {$value}   
                        }</input></td>
                        <td><input id="{concat('keep_', $name)}" type="checkbox" name="{concat('keep_', $name)}"/></td>
                      </tr> 
                  else ()
                }
              </table>
              <button id="importTable">Import table</button>
              <span id="results"></span>
            </div>
            </div>
          else ()
        }
      </div>
    </body>
  </html>
};

declare 
  %rest:path('check_db')
  %output:method("json")
  %rest:form-param("bdd", "{$bdd}")
function page:dotsCreate($bdd) {
  <json type="object">
    <message>{
      if (db:exists($bdd))
      then
        string("Database exists")
      else
        "Database does not exist. Please try again"
    }</message>
  </json>
};

declare
  %rest:POST
  %rest:path("/upload")
  %rest:form-param("bdd2", "{$bdd2}")
  %rest:form-param("file", "{$file}")
  %rest:form-param("boolean", "{$boolean}")
updating function page:upload($bdd2, $file, $boolean) {
  let $name    := map:keys($file)
  let $content := $file($name)
  let $path    := file:base-dir() || $name
  let $doc := file:write-binary($path, $content)
  let $ctt := file:read-text($path)
  let $csv := csv:parse($ctt, map { 'header': true() })
  return 
    (
      if (db:exists($bdd2, "metadata/metadata.csv"))
      then db:put($bdd2, $csv, "metadata/metadata.csv")
      else db:add($bdd2, $csv, "metadata/metadata.csv"),
      if ($boolean) 
      then update:output(web:redirect(concat("/dots/configuration?csv=true&amp;check=true&amp;bdd=", $bdd2)))
      else update:output(web:redirect(concat("/dots/configuration?csv=true&amp;bdd=", $bdd2)))
    )
};

declare updating
  %rest:POST
  %rest:path("/dots/createDocs")
  %rest:form-param("data", "{$data}")
  %rest:form-param("bdd", "{$bdd}")
  %rest:form-param("title", "{$title}")
function page:createDocs($data, $bdd, $title) {
  let $json := json:parse($data)
  return
    (
      page:createDeclaration($bdd, $json),
      cc:create_config($bdd, $title, "", 0, true())
    )
};

declare updating function page:createDeclaration($bdd, $json) {
  let $content := 
    <dots:metadatas>{
      for $object in $json//_
      let $type := $object/name
      let $typeName := substring-after($type, "_")
      group by $typeName
      return
        if ($object/name[. = concat("keep_", $typeName)])
        then
          if ($object/name[. = concat("xpath_", $typeName)])
          then 
            let $output := $object[name = concat("output_", $typeName)]
            let $xpath := $object[name[. = concat("xpath_", $typeName)]]/value
            let $elementName :=
              if ($output/value = "")
              then substring-after($output/name, "_")
              else normalize-space($output/value)
            let $prefix := normalize-space($object[name = concat("prefix_", $typeName)]/value)
            let $suffix := normalize-space($object[name = concat("suffix_", $typeName)]/value)
            return
               element {$elementName} {
                attribute {"element"} {substring-after($output/name, "_")},
                attribute {"xpath"} {$xpath},
                attribute {"format"} {"xml"},
                if ($prefix = "") then () else attribute {"prefix"} {$prefix},
                if ($suffix = "") then () else attribute {"suffix"} {$suffix}
               }  
          else
            let $output := $object[name = concat("output_", $typeName)]
            let $elementName :=
              if ($output/value = "")
              then substring-after($output/name, "_")
              else normalize-space($output/value)
            let $prefix := normalize-space($object[name = concat("prefix_", $typeName)]/value)
            let $suffix := normalize-space($object[name = concat("suffix_", $typeName)]/value)
            return
              element {$elementName} {
                attribute {"element"} {substring-after($output/name, "_")},
                attribute {"target"} {"/metadata/metadata.csv"},
                attribute {"format"} {"csv"},
                if ($prefix = "") then () else attribute {"prefix"} {$prefix},
                if ($suffix = "") then () else attribute {"suffix"} {$suffix}
               }  
    }</dots:metadatas>
  return
    if (db:exists($bdd, "declaration.xml"))
    then
      (
        replace value of node db:get($bdd, "declaration.xml")//dots:lastUpdate with current-dateTime(),
        replace node db:get($bdd, "declaration.xml")//dots:metadatas with $content
      )
    else
      let $decl := 
        <dots:configuration
        xmlns:dct="http://purl.org/dc/terms/"
        xmlns:dots="http://path/to/schema/dts/1.0#"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:html="http://www.w3.org/1999/xhtml"
        >
          <dots:configMetadata>
            <!-- version git du fichier -->
            <dots:gitVersion/>
            <dots:creationDate>{current-dateTime()}</dots:creationDate>
            <!-- date de création du document -->
            <dots:lastUpdate>2023-05-09T14:45:55.873+02:00</dots:lastUpdate>
            <!-- date de la dernière mise à jour -->
            <dots:publisher>École nationale des chartes</dots:publisher>
            <dots:description>Document déclaratif pour établir une concordance entre des métadonnées utilisateurs et le format de données souhaité en DTS</dots:description>
            <dots:licence>https://opensource.org/license/mit/</dots:licence>
          </dots:configMetadata>
          <dots:configContent>{$content}</dots:configContent>
        </dots:configuration>
      return
        db:add($bdd, $decl, "declaration.xml")
};


