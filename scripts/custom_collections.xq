import module namespace script = "script";

declare variable $srcPath external := ();

if (not($srcPath)) then (
  script:usage(
    static-base-uri(),
    "Create new collections and associate documents with them.",
    [ "srcPath", "absolute path to collections metadata tsv file", "path/to/tsv/file)"]
  )
) else (
  script:execute('create_custom_collections', map { 'srcPath': $srcPath })
)
