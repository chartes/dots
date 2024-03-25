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
    echo "  --project_dir_path    absolute path to import folder"
    echo "          (example: /absolute/path/to/import/folder)"
    echo "  --top_collection_id   tag of the image to deploy"
    echo "          (example: theater)"
    echo "  --db_name     basex db project name"
    echo "          (example: theater)"
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

cd ../../../bin
bash basex ../webapp/dots/scripts/dots_db_init.xq;

if [ $cleanOption ]; then
  if [ $delete ]; then
    if [ $delete == "true" ]; then
      bash basex -b dbName=$db_name -b option=true ../webapp/dots/scripts/dots_registers_delete.xq
    else
      bash basex -b dbName=$db_name -b option=false ../webapp/dots/scripts/dots_registers_delete.xq
    fi
  fi
fi
bash basex -b dbName=$db_name -b projectDirPath=$project_dir_path ../webapp/dots/scripts/project_db_init.xq;
bash basex -b dbName=$db_name -b topCollectionId=$top_collection_id ../webapp/dots/scripts/project_registers_create.xq;
bash basex -b dbName=$db_name ../webapp/dots/scripts/dots_switcher_update.xq
