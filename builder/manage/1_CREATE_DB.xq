xquery version '3.0' ;

import module namespace dbc = "https://github.com/chartes/dots/db/dbc" at "../../db/db_creator.xqm";

declare variable $dbName external; 
declare variable $pathPaquet external;

dbc:dbCreate($dbName, $pathPaquet)
