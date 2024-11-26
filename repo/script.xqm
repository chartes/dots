module namespace script = 'script';

(:~ 
 : Runs a script (later: can be replaced with job:execute in a future version)
 : @param  $name       name of script
 : @param  $variables  optional variable bindings
 : @return result of script
 :)
declare function script:run(
  $name       as xs:string,
  $variables  as map(*)?
) as item()* {
  let $id := job:eval(xs:anyURI($name), $variables, map { 'cache': true() })
  return (job:wait($id), job:result($id))
};


(:~ 
 : Returns a success message.
 : @param  $info  message parts
 : @return success message
 :)
declare %updating function script:success(
  $info  as xs:string*
) {
  update:output(concat("* ✅ ", $info, '&#10;'))
};

(:~ 
 : Returns an error message.
 : @param  $info  message parts
 : @return failure message
 :)
declare %updating function script:error(
  $info  as xs:string*
) {
  update:output(concat("* ❌ Erreur: ", $info, '&#10;'))
};
