xquery version '3.0' ;

import module namespace test = "https://github.com/chartes/dots/tests" at "utilsTest.xqm";
import module namespace initTests = "https://github.com/chartes/dots/initTests" at "initTestsEndpoint.xqm";


(: Lance les tests pour vérifier que la base du résolveur DTS est opérationnelle :)
initTests:check-value-response200("http://localhost:8080/api/dts"), (: le entrypoint doit renvoyer une réponse 200 :)
initTests:check-value-response200("http://localhost:8080/api/dts/collection"), (: le endpoint collection doit renvoyer une réponse 200 :)
initTests:check-value-response400("http://localhost:8080/api/dts/navigation"), 
initTests:check-value-response400("http://localhost:8080/api/dts/document") (: les endpoints navigation et document ne peuvent pas être opérationnels avant la création d'un projet-racine. La réponse correctement paramétrée est donc une erreur 400 :)

