#!/bin/bash

DIRECTORY="/home/andreg-p/arxmliv/no_warning"

for i in {1..64} do
	# get the name without path and file extensions
	echo "Move $i"
	$(mkdir $DIRECTORY/$i)
	$(mv `ls | head -10000` $DIRECTORY/$i)
	echo "Done moving $i"
done

echo "Process finished"
