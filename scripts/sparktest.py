from pyspark.mllib.clustering import KMeans
from numpy import array
import sys
from pyspark import SparkContext
from pyspark import StorageLevel

if __name__ == '__main__':
   
    if len(sys.argv)!=5:
        sys.exit("provide an app name a hdfs url input file max number of iterations and number of clusters")

    master = "hdfs://192.168.5.142:9000"
    sc = SparkContext(appName=str(sys.argv[1]))

    #Load testdata from HDFS 
    rawData = sc.textFile(master+str(sys.argv[2]),608)
    parsedData = rawData.map(lambda line: array([float(x) for x in line.split(' ')])).persist(StorageLevel(True,True,False,False,1))

    #Kmeans MODEL with train method of Kmeans
    kmeansModel = KMeans.train(parsedData,int(sys.argv[4]),maxIterations=int(sys.argv[3]),initializationMode="random")
    #print(kmeansModel.centers)
    #parsedData.unpersist()
    print
    for i in kmeansModel.clusterCenters:
        for j in i:
            print j,
        print
    sc.stop()
