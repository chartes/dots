xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/dots_switcher_update.xqm";

declare variable $dbName external;

dots.lib:switcher_update("encpos")