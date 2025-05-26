for $i in random:seeded-permutation(0, 1 to 500000)
let $record := db:get('encpos.tsv')/csv/record[id = 'ENCPOS_' || $i]
let $author := data($record/author)
return $author
