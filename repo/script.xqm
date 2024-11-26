module namespace script = 'script';

(:~ 
 : Executes a script (later: can be replaced with job:execute in a future version)
 : @param  $name       name of script
 : @param  $variables  optional variable bindings
 : @return result of script
 :)
declare function script:execute(
  $name       as xs:string,
  $variables  as map(*)?
) as item()* {
  (: with current versions of BaseX: job:execute(xs:anyURI($name), $variables) :)
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
  update:output(concat("* ❌ Erreur : ", $info, '&#10;'))
};

(:~ 
 : Returns some usage information.
 : @param  $uri        URI of the script
 : @param  $header     short description
 : @param  $variables  variables: [name, info, example]
 : @return info string
 :)
declare function script:usage(
  $uri        as xs:string,
  $header     as xs:string,
  $variables  as array(*)*
) as xs:string {
  string-join((
    $header, '',
    'Usage: basex ' || ($variables ! ('-' || .(1) || '=... ')) || file:name($uri), '',
    for $v in $variables
    return (
      '  ' || $v(1) || '  ' || $v(2),
      '      (example: ' || $v(3) || ')'
    ), ''
  ), '&#xa;')
};
