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
    echo "usage: $programname --db_name string --doc_path string "
    echo ""
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  --collection_id string  collection identifier"
    echo "                          "
    echo "  --basex_path string     absolute path to the basex folder 'bin'"
    echo "                          (example: /absolute/path/to/basex/bin)"
    echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $db_name ]]; then
    usage
    die "Missing parameter --db_name"
elif [[ -z $collection_id string ]]; then
    usage
    die "Missing parameter --collection_id string"
elif [[ -z $basex_path ]]; then
    usage
    die "Missing parameter --basex_path"
fi

bash "$basex_path/basex" -b dbName=$db_name -b docPath=$doc_path scripts/add_collection.xq
