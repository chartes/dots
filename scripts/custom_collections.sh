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
    echo "Create new collections and associate documents with them"
    echo ""
    echo "usage: $programname --collections_tsv_path string "
    echo ""
    echo "  --basex_path string   absolute path to the basex folder 'bin'"
    echo "          (example: /absolute/path/to/basex/bin)"
    echo ""
    echo "  --collections_tsv_path string		absolute path to collections metadata tsv file"
    echo "          (example: path/to/tsv/file)"
    echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $collections_tsv_path ]]; then
    usage
    die "Missing parameter --collections_tsv_path"
elif [[ -z $basex_path ]]; then
    usage
    die "Missing parameter --basex_path"
fi

bash "$basex_path/basex" -b srcPath=$collections_tsv_path scripts/create_custom_collections.xq