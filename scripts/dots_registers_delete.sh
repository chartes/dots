#!/bin/bash

cd ../../../bin

if [ $delete == "true" ]; then
  bash basex -b dbName=$dbName -b option=true ../webapp/dots/scripts/dots_registers_delete.xq
else
  bash basex -b dbName=$dbName -b option=false ../webapp/dots/scripts/dots_registers_delete.xq
fi
