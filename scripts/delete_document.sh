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
    echo "Delete a document from an existing DoTS project"
    echo ""
    echo "usage: $programname --db_name string --doc_id string "
    echo ""
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  --doc_id string       absolute path to the document to add"
    echo "                          "
    echo "  --basex_path string       absolute path to the basex folder 'bin'"
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
elif [[ -z $doc_id ]]; then
    usage
    die "Missing parameter --doc_id"
elif [[ -z $basex_path ]]; then
    usage
    die "Missing parameter --basex_path"  
fi

bash "$basex_path/basex" -b dbName=$db_name -b docId=$doc_id scripts/delete_document.xq
