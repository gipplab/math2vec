#!/bin/bash

DIRIN="~/arxmliv/no_problems_raw"
DIRPROC="~/arxmliv/no_problems_txt"
DIROUT="~/arxmliv/no_problems_tmp"

for file in $(ls $DIRIN); do
	name=${file%.*}
	if ! [[ -f "$DIRPROC/$name.txt" ]]; then
		echo "$name was not processed yet => move to output directory..."
		$(cp $DIRIN/$name.html $DIROUT/$name.html)
	fi
done	
