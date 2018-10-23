#!/bin/bash

DIRIN="/home/andreg-p/arxmliv/no_problems_raw"
DIRPROC="/home/andreg-p/arxmliv/no_problems_txt"
DIROUT="/home/andreg-p/arxmliv/no_problems_tmp"

for file in $(ls $DIRIN); do
	name=${file%.*}
	if ! [[ -f "$DIRPROC/$name.txt" ]]; then
		echo "$name was not processed yet => move to output directory..."
		$(cp $DIRIN/$name.html $DIROUT/$name.html)
	fi
done	
