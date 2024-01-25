xquery version '3.0' ;

import module namespace dots.switcher = "https://github.com/chartes/dots/builder/switcher" at "../db_switch_builder.xqm";

declare variable $dbName external;
declare variable $topCollectionId external;

dots.switcher:createSwitcher($dbName, $topCollectionId)