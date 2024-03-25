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


cd ../../../bin

if [ $db_delete == "false" ]; then
  bash basex -b dbName=$db_name -b option=false ../webapp/dots/scripts/dots_registers_delete.xq
else
  bash basex -b dbName=$db_name -b option=true ../webapp/dots/scripts/dots_registers_delete.xq
fi
