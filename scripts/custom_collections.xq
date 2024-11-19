declare variable $srcPath external;

let $eval := function($script) {
  let $id := job:eval(
    xs:anyURI($script),
    map {
      'collections_tsv_path': $srcPath
    },
    map { 'cache': true() }
  )
  return (job:wait($id), job:result($id))
}
return (
  $eval('create_custom_collections.xq')
)
