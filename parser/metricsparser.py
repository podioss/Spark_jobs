#!/usr/bin/python
from __future__ import print_function
from datetime import datetime
import sys

#the script operates in the same dir with the ganglia stats

if len(sys.argv)!=3:
	sys.stderr.write("Usage: ./metricsparser.py inputStats outputStats\n")
	raise SystemExit(1)

try:
	ifd=open(sys.argv[1],"r") #input file
	ofd=open(sys.argv[2],"w") #output file
except:
	sys.stderr.write("An error occured while trying to open the files")
	raise SystemExit(1)


# strip new line character from the end and collect the actual data from the file 
lines = [line.rstrip() for line in ifd.readlines() if line[0]!=' ' and line[0]!='\n']
ifd.close()


for line in lines:
	line=line.split(":")
	timestamp=datetime.fromtimestamp(int(line[0])).strftime('%Y-%m-%d %H:%M:%S')
	data=float(line[1])
	print(timestamp,data,sep=',',end='\n',file=ofd)
ofd.close()
#print datetime.fromtimestamp(int(line[0])).strftime('%Y-%m-%d %H:%M:%S'),
#print " %f"%(float(line[1]))

