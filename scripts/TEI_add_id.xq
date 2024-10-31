xquery version '3.0' ;

import module namespace dots.update = "https://github.com/chartes/dots/lib" at "../lib/TEI_add_id.xqm";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare variable $dbName external;

dots.update:addXmlIdToFragment($dbName),
update:output("* ✅ DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.
  ")