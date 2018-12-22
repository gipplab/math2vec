#!/bin/bash
cpu=0
for process in {1..10}; do  
  python3 postagger.py --input files/input/train/$process --output files/output &
  cpu=$((cpu+1))  
  if [ $(($cpu % 10)) == 0 ]
  then
    wait
  fi
done
wait
