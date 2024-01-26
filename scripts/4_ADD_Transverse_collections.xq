xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/documents_in_multiple_collections.xqm";
import module namespace dots.validate = "https://github.com/chartes/dots/validation" at "../validation/dots_data_validation.xqm";

declare variable $srcPath external;

dots.lib:handle($srcPath)