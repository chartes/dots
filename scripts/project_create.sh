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
    echo "Load a project import folder in basex"
    echo ""
    echo "usage: $programname --project_dir_path string --top_collection_id string --db_name string "
    echo ""
    echo "  --basex_path string   absolute path to the basex folder 'bin'"
    echo "          (example: /absolute/path/to/basex/bin)"
    echo "  --project_dir_path    absolute path to import folder"
    echo "          (example: /absolute/path/to/import/folder)"
    echo "  --top_collection_id   project root id"
    echo "          (example: theater)"
    echo "  --db_name             basex db project name"
    echo "          (example: theater)"
    echo "  --cleanOption         option to delete previous DoTS project"
    echo "          (default: false)"
    echo "  --delete              choice to delete only registers or all the database"
    echo "          (default: false)"
    echo "  --unit_test           choice to launch unit tests"
    echo "          (default: false)"
    echo ""
}

function die {
    printf "Script failed: %s\n\n" "$1"
    exit 1
}

if [[ -z $project_dir_path ]]; then
    usage
    die "Missing parameter --project_dir_path"
elif [[ -z $top_collection_id ]]; then
    usage
    die "Missing parameter --top_collection_id"
elif [[ -z $db_name ]]; then
    usage
    die "Missing parameter --db_name"
fi

bash basex scripts/dots_db_init.xq;

if [ $cleanOption ]; then
  if [ $delete ]; then
    if [ $delete == "true" ]; then
      bash "$basex_path/basex" -b dbName=$db_name -b option=true scripts/dots_registers_delete.xq
    else
      bash "$basex_path/basex" -b dbName=$db_name -b option=false scripts/dots_registers_delete.xq
    fi
  fi
fi
bash "$basex_path/basex" -b dbName=$db_name -b projectDirPath=$project_dir_path scripts/project_db_init.xq;
bash "$basex_path/basex" -b dbName=$db_name -b topCollectionId=$top_collection_id scripts/project_registers_create.xq;
bash "$basex_path/basex" -b dbName=$db_name scripts/TEI_add_id.xq;
bash "$basex_path/basex" -b dbName=$db_name scripts/dots_switcher_update.xq;

if [ $unit_test == 'true()' ]; then
  bash "$basex_path/basex" -b dbName=$db_name -b projectDirPath=$project_dir_path -b topCollectionId=$top_collection_id -b option='false()' -t tests/project_create
fi
  
