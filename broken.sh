#!/bin/bash

INPUT="/home/andreg-p/arxmliv/no_problems_raw"
OUTPUT="/home/andreg-p/arxmliv/no_problems_broken"
PROC="/home/andreg-p/arxmliv/no_problems_txt"

PATTERN="<!DOCTYPE html><html>
<head>
<title>Untitled Document</title>"

for file in $(ls $INPUT); do
	lines=$(head -3 $INPUT/$file)
	name=${file%.*}
	if [[ $lines == $PATTERN ]]; then
		echo "Hit on $name - moving to no_problems_broken."
		$(cp $INPUT/$file $OUTPUT/$name.html)
		$(mv $PROC/$name.* $OUTPUT)
	fi
done

