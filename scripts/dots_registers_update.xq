xquery version '3.0' ;

import module namespace dots.update = "dots_registers_update";
import module namespace G = "globals";

declare variable $dbName external;

dots.update:updateFragments_register($dbName),
update:output("
* ✅ DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.
  ")