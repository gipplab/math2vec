#!/bin/bash

INPUT="errors.txt"
RAW="/home/andreg-p/arxmliv/no_problems_raw"
OUTPUT="/home/andreg-p/arxmliv/no_problems_broken"

files=$(cat $INPUT)

for file in $files; do
	$(cp $RAW/$file $OUTPUT/$file)
done
