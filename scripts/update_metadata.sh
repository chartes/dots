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
    echo "Update the metadata file in a DoTS project"
    echo ""
    echo "usage: $programname --basex_path string --db_name string --project_dir_path string"
    echo ""
    echo "  --basex_path string     absolute path to the basex folder 'bin'"
    echo "                          (example: /absolute/path/to/basex/bin)"
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo "  --project_dir_path      absolute path to import folder"
    echo "                          (example: /absolute/path/to/import/folder)"
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

bash "$basex_path/basex" -b dbName=$db_name -b projectDirPath=$project_dir_path scripts/update_metadata.xq

