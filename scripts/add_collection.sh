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
    echo "Add a new collection to an existing DoTS project"
    echo ""
    echo "usage: $programname --basex_path string --db_name string --collection_id string"
    echo ""
    echo "  --basex_path string     absolute path to the basex folder 'bin'"
    echo "                          (example: /absolute/path/to/basex/bin)"
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  --collection_id string  identifier of the collection"
    echo "                          "
    echo "  [--parent_id] string    by default (top_collection_id) : identifier of the parent collection"
    echo "                          "
    echo "  [--unit_test] boolean   by default (false) true: launch unit tests"
    echo "                          (example: false)"echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $basex_path ]]; then
    usage
    die "Missing parameter --basex_path"
elif [[ -z $db_name ]]; then
    usage
    die "Missing parameter --db_name"
elif [[ -z $collection_id ]]; then
    usage
    die "Missing parameter --collection_id"
fi

bash "$basex_path/basex" -b dbName=$db_name -b resourceId=$collection_id -b parentId=$parent_id  scripts/add_collection.xq;

if [[ $unit_test == 'true' ]]; then
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/project_registers_create_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/TEI_add_id_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/dots_switcher_update_test.xq;
fi










