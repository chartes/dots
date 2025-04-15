xquery version '3.0' ;

import module namespace dots.update = "backend/dots_registers_update";
import module namespace script = "script";

declare variable $dbName external := ();

dots.update:updateFragments_register($dbName),
script:success("DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.")
