declare variable $db_name external;
declare variable $option external;

let $eval := function($script) {
  let $id := job:eval(
    xs:anyURI($script),
    map {
      'dbName': $db_name,
      'option': $option
    },
    map { 'cache': true() }
  )
  return (job:wait($id), job:result($id))
}
return (
  $eval('dots_registers_delete.xq')
)
