xquery version '3.0' ;

import module namespace dots.update = "backend/TEI_add_id";
import module namespace G = "globals";
import module namespace script = "script";

declare variable $dbName external;


dots.update:addXmlIdToFragment($dbName),
script:success("DoTS a intégré, le cas échéant, des attributs @xml:id aux fragments.")