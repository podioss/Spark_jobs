#!/bin/bash
for i in {5..8}
do
	./randgenim.py -d 5 -n $[10**i] n${i}d5
done 
