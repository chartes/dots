xquery version '3.0' ;

import module namespace test = "https://github.com/chartes/dots/tests" at "utilsTest.xqm";
import module namespace initTests = "https://github.com/chartes/dots/initTests" at "initTestsEndpoint.xqm";


(:  :)
initTests:check-value-response200("http://localhost:8080/api/dts"),
initTests:check-value-response200("http://localhost:8080/api/dts/collection"),
initTests:check-value-response400("http://localhost:8080/api/dts/navigation"),
initTests:check-value-response400("http://localhost:8080/api/dts/document")

