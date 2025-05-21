declare variable $TSV := map:merge(
  for $record in db:get('encpos.tsv')/csv/record
  return map:entry(
    $record/id,
    map:merge(
      for $field in $record/(* except id)
      return map:entry(name($field), data($field))
    )
  )
) => prof:time('Build index: ');

for $i in random:seeded-permutation(0, 1 to 500000)
let $record := $TSV('ENCPOS_' || $i)
let $author := $record?author
return $author
