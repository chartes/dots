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
    echo "usage: $program name --basex_path string --db_name string --resource_id string "
    echo ""
    echo "  --basex_path string   absolute path to the basex folder 'bin'"
    echo "          (example: /absolute/path/to/basex/bin)"
    echo ""
    echo "  --db_name string        basex project db name"
    echo "                          (example: theater)"
    echo ""
    echo "  --resource_id string    identifier of the collection to delete"
    echo ""
    echo "  [--project_dir_path]      absolute path to import folder"
    echo "          (example: /absolute/path/to/import/folder)"
    echo ""
    echo "  [--delete_resources boolean]      option to delete documents that belongs to the collection"
    echo "                          (default: false())"
    echo ""
    echo "  [--unit_test]           choice to launch unit tests"
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
elif [[ -z $basex_path ]]; then
    usage
    die "Missing parameter --basex_path"
elif [[ -z $resource_id ]]; then
    usage
    die "Missing parameter --resource_id"
fi

bash "$basex_path/basex" -b dbName=$db_name -b resourceId=$resource_id -b projectDirPath=$project_dir_path -b deleteResources=$delete_resources scripts/remove_collection.xq

if [[ $unit_test == 'true' ]]; then
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/project_registers_create_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/TEI_add_id_test.xq;
  bash "$basex_path/basex" -b dbName=$db_name -t tests/project_create/dots_switcher_update_test.xq;
fi
