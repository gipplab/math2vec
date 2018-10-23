#!/bin/bash

INPUT="/home/andreg-p/arxmliv/no_problems_txt"
RAW="/home/andreg-p/arxmliv/no_problems_raw"
OUTPUT="/home/andreg-p/arxmliv/no_problems_broken"

echo "Identify files smaller than 40 bytes."

# requesting all files that are smaller than 40 bytes -> most likely broken
files=$(find $INPUT/ -maxdepth 1 -type f -size -40c -printf "%P ")

echo "Identified files... start moving them to $OUTPUT"

for file in $files; do
	# get the name without path and file extensions
	name=${file%.*}
	$(mv $INPUT/$name.* $OUTPUT)
	$(mv $RAW/$name.* $OUTPUT)
done

echo "Process finished"
