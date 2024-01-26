xquery version "3.1";

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/dots_registers_delete.xqm";

declare variable $dbName external; 

dots.lib:handleDelete($dbName)