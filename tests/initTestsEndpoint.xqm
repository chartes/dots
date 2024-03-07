xquery version '3.0' ;

module namespace initTests = "https://github.com/chartes/dots/initTests";

declare function initTests:endpoint($url) {
  let $statutCode := http:send-request(<http:request method='get' status-only='true'/>, $url)
  return
    normalize-space($statutCode/@status)
};

declare %unit:test function initTests:check-value-response200($url) {
  let $expected := "200"
  return
    unit:assert-equals(initTests:endpoint($url), $expected)
};

declare %unit:test function initTests:check-value-response400($url) {
  let $expected := "400"
  return
    unit:assert-equals(initTests:endpoint($url), $expected)
};