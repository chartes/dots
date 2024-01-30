xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/create_custom_collections.xqm";

declare variable $srcPath external;

dots.lib:handle($srcPath)