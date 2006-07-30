#!/bin/bash

tables="cast director flag flag2title genre keyword keyword2title name producer title writer"

for t in $tables
do
	mysql -u nicolaw --database="dvds" --execute="delete from $t"
done


