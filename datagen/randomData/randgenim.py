#!/usr/bin/python
# A script in python to generate the various datasets needed for kmeans algorithm
#----------OPTIONS----------
# dimension of the generated points (not configurable) 
# number of total points generated ==> size of the dataset generated
# the name of the generated file as a leftover command argument 
###############                 THIS SCRIPT GENERATES RANDOM DATA POINTS AS A TEST FOR THE KMEANS ALGORITHM         ###################
from __future__ import print_function
import random as r
from optparse import OptionParser
import sys


# create random lines that represent the generated data points
# boundary set to maxint 
def get_line(x):
    rand_line = [] 
    for i in xrange(x):
        rand_line.append(r.randint(-sys.maxint,sys.maxint))
    return rand_line


parser = OptionParser()

# add dimension option of the data points
parser.add_option("-d","--dimension",default=0,
		 help="dimension of data points generated",
		 action="store",type="int",dest="d",metavar="num")
# add number of data points option 
parser.add_option("-n","--number",default=0,
		 help="number of points to be generated",
		 action="store",type="int",dest="n",metavar="num")

# parse the commmand's options and the related values
(options,args) = parser.parse_args()

if len(args)!=1:
    sys.exit("Invalid file name argument given")

f = open(args[0],"w")
for i in xrange(options.n):
    line = get_line(options.d)
    for i in xrange(options.d-1):
        print(line[i],end=' ',file=f)
    print(line[-1],file=f)

f.close()
