xquery version '3.0' ;

import module namespace dots.update = "TEI_add_id";
import module namespace G = "globals";

declare variable $dbName external;

dots.update:addXmlIdToFragment($dbName),
update:output("* ✅ DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.
  ")