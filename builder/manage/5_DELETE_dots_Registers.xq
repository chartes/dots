xquery version "3.1";

import module namespace dbd = "https://github.com/chartes/dots/db/dbd" at "../../db/dots_registers_delete.xqm";

declare variable $dbName external; 

dbd:handleDelete($dbName)