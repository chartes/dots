xquery version '3.0' ;

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/db_switch_builder.xqm";

dots.lib:dots_db_init(),
update:output("La base de donnée dots a été initialisée
")