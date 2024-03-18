xquery version '3.0' ;

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace test = "https://github.com/chartes/dots/tests" at "utilsTest.xqm";
import module namespace initTests = "https://github.com/chartes/dots/initTests" at "initTestsEndpoint.xqm";
import module namespace deployTest = "https://github.com/chartes/dots/deploimentTests" at "deploimentTests.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Deploiment Tests  :)
(: "> Starting deploiment tests in progress...",

"test init dots db...",
(: create a specific function "checkDotsExists" in deploimentTests.xqm :)

(: Check if db dots exists :)
(deployTest:check-boolean-response(db:exists($G:dots)), "* ✅ DoTS Db created with success"),
(: Compare new switcher dots with switcher dots model :)
(: (deployTest:check-boolean-response(deployTest:testDbSwitch()), "* ✅ DoTS Db switcher created with success"), :)
(: Compare new default mapping dots with default mapping dots model :)
(deployTest:check-boolean-response(deployTest:testMetadataMapping()), "* ✅ DoTS Db default metadata mapping created with success"),

deployTest:checkTotalResources(deployTest:getNumberResources()), "* ✅ Total resources successfully counted", :)

for $encposDoc in db:get("encpos")/tei:TEI
let $idDoc := $encposDoc/@xml:id
let $path := concat($G:webapp, "dots/tests/data_model/encpos/data")
let $coll := collection($path)/tei:TEI[@xml:id = $idDoc]
return
  deployTest:deepEqual($encposDoc, $coll)
 
 






(: deployTest:check-boolean-response(deployTest:testDbSwitch()),
deployTest:check-boolean-response(deployTest:testMetadataMapping()), :)

(: 
Check data in database 
input:
  XML from database ...
return : 
  OK (str)
:)

(: ... :)

(: "> ✅ deploiment tests checked",

(: Backend Tests  :)
"> Starting backend tests in progress...",

(: ... :)

"> ✅ backend tests checked",

(: API Tests :) 
"> Starting API tests in progress...",

(: Lance les tests pour vérifier que la base du résolveur DTS est opérationnelle :)
initTests:check-value-response200("http://localhost:8080/api/dts"), (: le entrypoint doit renvoyer une réponse 200 :)
initTests:check-value-response200("http://localhost:8080/api/dts/collection"), (: le endpoint collection doit renvoyer une réponse 200 :)

(: TODO : create tests for 400 in the future :)

"> ✅ API tests checked" :)

