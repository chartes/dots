xquery version '3.0' ;

import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace test = "https://github.com/chartes/dots/tests" at "utilsTest.xqm";
import module namespace initTests = "https://github.com/chartes/dots/initTests" at "initTestsEndpoint.xqm";
import module namespace deployTest = "https://github.com/chartes/dots/deploimentTests" at "deploimentTests.xqm";

declare default element namespace "https://github.com/chartes/dots/";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Deploiment Tests  :)
"> Starting deploiment tests in progress...",

if (deployTest:check-boolean-response(db:exists($G:dots)))
then "* ❌ No Db DoTS"
else
  "* ✅ DoTS Db created with success", 



deployTest:checkTotalResources(deployTest:getNumberResources()), "* ✅ Total resources successfully counted",

for $encposDoc in db:get("encpos")/tei:TEI
let $idDoc := $encposDoc/@xml:id
let $path := concat($G:webapp, "dots/tests/data_model/encpos/data")
let $coll := collection($path)/tei:TEI[@xml:id = $idDoc]
return
  deployTest:deepEqual($encposDoc, $coll),
  
"* ✅ TEI documents creation checked",
 
let $resources_register := db:get("encpos", "dots/resources_register.xml")//member
let $fragments_register := db:get("encpos", "dots/fragments_register.xml")//member
let $model_register := concat($G:webapp, "dots/tests/data_model/encpos/dots_registers/")
let $model_resources_register := doc(concat($model_register, "resources_register.xml"))//member
let $model_fragments_register := doc(concat($model_register, "fragments_register.xml"))//member
return
  (
    deployTest:deepEqual($resources_register, $model_resources_register),
    deployTest:deepEqual($fragments_register, $model_fragments_register)
  ),

"* ✅ DoTS registers creation checked",

let $count_N :=
  for $frag in db:get("encpos", "dots/fragments_register.xml")//member/fragment
  let $n := $frag/@n
  group by $n
  let $count := count($n)
  return
    $count
return
  deployTest:check-N-Values(max($count_N)),
  
"* ✅ values of attributes '@n' for fragments checked",
"> ✅ deploiment tests checked"

(: ... :)

(: 

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

