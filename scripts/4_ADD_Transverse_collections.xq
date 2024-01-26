xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/documents_in_multiple_collections.xqm";

declare variable $srcPath external;

dots.lib:handle($srcPath)