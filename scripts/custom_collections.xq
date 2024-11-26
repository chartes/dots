import module namespace script = "script";

declare variable $srcPath external := ();

if (not($srcPath)) then (
  "Create new collections and associate documents with them.
usage: basex -bsrcPath=... " || file:name(static-base-uri()) || "

  srcPath  absolute path to collections metadata tsv file
           (example: path/to/tsv/file)
"
) else (
  script:run('create_custom_collections.xq', map { 'srcPath': $srcPath })
)
