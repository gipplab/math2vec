#!/bin/bash

INPUTDIR="/home/andreg-p/arxmliv/warning_raw"
OUTPUTDIR="/home/andreg-p/arxmliv/warning_txt"

for i in {61..64}
do
	echo "Start process $i"
	./bin/planetext arxiv.yaml $INPUTDIR/$i -O $OUTPUTDIR -m 8 &
done
wait
