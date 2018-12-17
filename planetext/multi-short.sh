#!/bin/bash

INPUTDIR="/home/andreg-p/arxmliv/warning_raw"
OUTPUTDIR="/home/andreg-p/arxmliv/warning_txt"

for i in {41..60}
do
	echo "Start process $i"
	./bin/planetext arxiv.yaml $INPUTDIR/$i -O $OUTPUTDIR -m 4 &
done
wait
