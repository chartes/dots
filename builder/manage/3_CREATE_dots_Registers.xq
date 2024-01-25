xquery version '3.0' ;

import module namespace cc = "https://github.com/chartes/dots/builder/cc" at "../resources_register_builder.xqm";

declare variable $dbName external;
declare variable $topCollectionId external;

cc:create_config($dbName, $topCollectionId)