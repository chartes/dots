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
    echo "Delete a collection from an existing DoTS project"
    echo ""
    echo "usage: $program name --db_name string --doc_id string "
    echo ""
    echo "  --basex_path string   absolute path to the basex folder 'bin'"
    echo "          (example: /absolute/path/to/basex/bin)"
    echo ""
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo ""
    echo "  --resource_id string    identifier of the collection to delete"
    echo ""
    echo "  --option boolean        option to delete documents that belongs to the collection"
    echo "                          (default: false())"
    echo ""
    echo "  --unit_test             choice to launch unit tests"
    echo "                          (default: false)"
    echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $db_name ]]; then
    usage
    die "Missing parameter --db_name"
elif [[ -z $resource_id ]]; then
    usage
    die "Missing parameter --resource_id"
elif [[ -z $option ]]; then
    usage
    die "Missing parameter --option"  
fi

bash "$basex_path/basex" -b dbName=$db_name -b resourceId=$resource_id -b option=$option scripts/delete_collection.xq

