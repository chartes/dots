xquery version '3.0' ;

import module namespace dots.update = "https://github.com/chartes/dots/lib" at "../lib/dots_registers_update.xqm";

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";

declare variable $dbName external;

dots.update:updateFragments_register($dbName),
update:output("
* ✅ DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.
  ")