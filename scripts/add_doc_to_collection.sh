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
    echo "Rely an existing document to an existing collection"
    echo ""
    echo "usage: $programname --basex_path string --db_name string --doc_id string --collection_id string"
    echo ""
    echo "  --basex_path string     absolute path to the basex folder 'bin'"
    echo "                          (example: /absolute/path/to/basex/bin)"
    echo ""
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  --doc_id string         identifier of the document"
    echo ""
    echo "  --collection_id string  identifier of the collection"
    echo "                          "
    echo "  [--unit_test] boolean   by default (false) true: launch unit tests"
    echo "                          (example: false)"
    echo ""
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
elif [[ -z $doc_id ]]; then
    usage
    die "Missing parameter --doc_id"
elif [[ -z $collection_id ]]; then
    usage
    die "Missing parameter --collection_id"
fi

bash "$basex_path/basex" -b dbName=$db_name -b docId=$doc_id -b collectionId=$collection_id  scripts/add_doc_to_collection.xq;

if [[ $unit_test == 'true' ]]; then
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/project_registers_create_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/TEI_add_id_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/dots_switcher_update_test.xq;
fi










