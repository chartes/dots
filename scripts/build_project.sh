#!/bin/bash

cd ../../../bin

bash basex ../webapp/dots/scripts/dots_db_init.xq;

bash basex -b dbName=$1 -b projectDirPath=$2 ../webapp/dots/scripts/project_db_init.xq;

bash basex -b dbName=$1 -b topCollectionId=$3 ../webapp/dots/scripts/project_registers_create.xq;

bash basex -b dbName=$1 ../webapp/dots/scripts/dots_switcher_update.xq