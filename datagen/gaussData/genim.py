#!/usr/bin/python
from numpy.random import normal
#import matplotlib.pyplot as plt
from random import randint
from math import sqrt
# from sys import maxint
from os.path import isfile
from os import makedirs
import argparse

parser = argparse.ArgumentParser(description='generates a file with 2d numerical points clustered'
                                             ' around the centroids with a random distance of a gaussian distribution')

parser.add_argument("-n","--number", help="how many points to plot",type=int, required=True)
parser.add_argument("--centroids", '-c', type=int, help="the number of centroids", required=True)
parser.add_argument("--outdir", '-o', help="the output directory", required=True)
parser.add_argument("--dimensions","-d",help="the dimensions of the datapoints",type=int,required=True)
args = parser.parse_args()



def gauss_2d(mean, sd,fd,dim,points=1):
    for i in xrange(points): #how many points around this centroid
        for d in xrange(dim):
            if d==dim-1:
                fd.write("%d\n"%(int(normal(mean[d],sd,1))))
            else:
                fd.write("%d "%(int(normal(mean[d],sd,1))))


#euclidean distance between two centroids
def lin_dist(x, y):
    a = [ pow(x[i]-y[i],2) for i in xrange(len(x)) ]
    # a = pow(x[0]-y[0], 2) + pow(x[1]-y[1], 2)
    return sqrt(sum(a))


def generate_points(num_points, clusters, dimensions, out_dir):
    if num_points<clusters:
        print "Cluster count is larger than points count. This is just wrong"
        exit(-2)

    #handle cluster sizes
    boundary = 1000000000  #1 billion 
    name = "%d_points_%d_clusters_%d_dimension" % (num_points, clusters,dimensions)
    num_points = num_points/clusters

    #output file
    name=out_dir+"/"+name
    fname = name
    if isfile(fname):
        print "file \"%s\" already exists. Skipping" % fname
        return
    try: makedirs(out_dir)
    except: pass
    out_file = open(fname, "w+")


    centroids=[]
    # create centroid of the required dimension and gather all the centroids in a list
    for i in xrange(clusters):
        centroid = []
        # as much coordinates as dimensions given
        for d in xrange(dimensions):
            centroid.append(randint(-boundary,boundary))
        centroids.append(centroid)
    
    # calculate for all the centroids the distances to all others and calculate the dist to the closest
    # add those min distances to the min_distances list
    min_distances = []
    if len(centroids) > 1:
        for i in xrange(len(centroids)):
            dist =[]
            for j in xrange(len(centroids)):
                if i==j: continue
                dist.append(lin_dist(centroids[i],centroids[j]))
            min_distances.append(min(dist))
    else:
        min_distances.append(boundary)

    for i in xrange(len(centroids)):
        sd = min_distances[i]/5
        # create the data point on the fly in the gauss_2d funct and write it to the file, *pass the file descriptor
        # to the function as well
        gauss_2d(centroids[i],sd,out_file,dimensions,num_points)

        # write to file
        # for d in range(len(x)): out_file.write("%d, %d\n" %(x[d],y[d]))


    out_file.close()

    #write info
    with open(name + "_centroids", "w") as text_file:
        for x,y in centroids:
            text_file.write("%d %d\n"%(x,y))

generate_points(args.number, args.centroids,args.dimensions, args.outdir)
