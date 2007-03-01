#!/bin/bash

for dir in `find /home/nicolaw/webroot/logs/ -type d`
do
	if cd $dir
	then
		echo "Processing $dir ..."
		/home/nicolaw/bin/splitlog.pl
		for i in `ls *.log-200* 2>/dev/null | egrep -v ".gz$"`
		do
			gzip $i
		done
		echo
	fi
done

