xquery version '3.0' ;

module namespace test = "https://github.com/chartes/dots/tests";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";

import module namespace dots.lib = "https://github.com/chartes/dots/lib" at "../lib/resources_register_builder.xqm";

(: UtilsTest.xqm 
: 
: Module pour tester (...)
:)

declare function test:fixture-OK() {
  string("vador")
};

(: Documentation du test :)
declare %unit:test function test:check-metadata-output() {
  let $expected := 
    "vador"
  return
    unit:assert-equals(test:fixture-OK(), $expected)
};

