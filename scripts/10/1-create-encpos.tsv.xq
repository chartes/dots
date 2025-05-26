let $csv := <csv>{
  for $i in 1 to 500000
  return <record>
    <id>ENCPOS_{ $i }</id>
    <author>{
      codepoints-to-string(
        for $j in 1 to 5 + xs:integer(random:double() * 10)
        return 97 + xs:integer(random:double() * 26)
      )
    }</author>
    <city>{
      codepoints-to-string(
        for $j in 1 to 5 + xs:integer(random:double() * 5)
        return 97 + xs:integer(random:double() * 26)
      )
    }</city>
  </record>
}</csv>
return db:create('encpos.tsv', $csv, 'encpos.tsv')
