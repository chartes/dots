#!/bin/bash

cd ../../../bin

bash basex ../webapp/dots/scripts/dots_db_init.xq;

if [ $cleanOption ]; then
  if [ $delete == "true" ]; then
    bash basex -b dbName=$dbName -b option=true ../webapp/dots/scripts/dots_registers_delete.xq
  else
    bash basex -b dbName=$dbName -b option=false ../webapp/dots/scripts/dots_registers_delete.xq
  fi
fi
bash basex -b dbName=$dbName -b projectDirPath=$projectDirPath ../webapp/dots/scripts/project_db_init.xq;

bash basex -b dbName=$dbName -b topCollectionId=$topCollectionId ../webapp/dots/scripts/project_registers_create.xq;

bash basex -b dbName=$dbName ../webapp/dots/scripts/dots_switcher_update.xq