#!/bin/bash

while [ $# -gt 0 ]; do
    if [[ $1 == "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

programname=$0
function usage {
    echo ""
    echo "Delete project db and clean dots register"
    echo ""
    echo "usage: $programname --db_name string --delete boolean "
    echo ""
    echo "  --basex_path string     absolute path to the basex folder 'bin'"
    echo "                          (example: /absolute/path/to/basex/bin)"
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  [--db_delete] boolean   by default delete (true) or keep (false) project db"
    echo "                          (example: false)"
    echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $db_name ]]; then
    usage
    die "Missing parameter --db_name"
fi


if [ $db_delete == "false" ]; then
  bash "$basex_path/basex" -b dbName=$db_name -b option=false scripts/dots_registers_delete.xq
else
  bash "$basex_path/basex" -b dbName=$db_name -b option=true scripts/dots_registers_delete.xq
fi
