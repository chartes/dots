import module namespace script = "script";

declare variable $dbName external := ();
declare variable $option external := ();

if (not($dbName and $option)) then (
  script:usage(
    static-base-uri(),
    "Delete project db and clean dots register",
    ([ "db_name", "basex db project name", "theater" ],
     [ "db_delete", "by default delete (true) or keep (false) project db", "false" ])
  )
) else (
  script:execute('dots_registers_delete.xq', map { 'dbName': $dbName, 'option': $option })
)
