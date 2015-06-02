#!/usr/bin/python
from __future__ import print_function
import sys
import math
if len(sys.argv)!=3:
	sys.stderr.write("Usage: ./memparser.py inFile outFile\n")
	raise SystemExit(1)
	
ifd=open(sys.argv[1],"r") #input file
ofd=open(sys.argv[2],"w") #output file

#4047552  8176312  16433520
mem_total=4047552  #total memory of the nodes in kb(=4GB)
mem_used_acc=0
counter=0
for line in ifd.readlines():
    fields=line.split(",")
    check=map(lambda x: math.isnan(float(x)),fields)
    if True in check:
    	continue
    counter+=1
    #print("Line %d sum is %f"%(counter,sum([float(x) for x in fields])))
    mem_used_acc+=mem_total-(sum([float(x) for x in fields]))
    #print("Mem used is %f"%(mem_total-(sum([float(x) for x in fields]))))
#print("counter is: %d"%counter)
average=mem_used_acc/counter
print(average,file=ofd)
ifd.close()
ofd.close()    
