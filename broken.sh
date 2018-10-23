#!/bin/bash

PATH="/home/andreg-p/arxmliv/no_problems_txt"
RAW="/home/andreg-p/arxmliv/no_problems_raw"
OUTPUT="/home/andreg-p/arxmliv/no_problems_broken"

# requesting all files that are smaller than 10 bytes -> most likely broken
for file in $(find $PATH/ -maxdepth 1 -type f -size -10c); do
	# get the name without path and file extensions
	name=${file%.*}
	echo "Found a file $name"
done
