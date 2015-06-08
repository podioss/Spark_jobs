#!/bin/bash

#this bash script runs all the jobs for a specific number of data points
#and a specific dimension. That way observations can be made
#independent of the variables that affect the overall size of the dataset

RRDS="/var/lib/ganglia/rrds/thesis-cluster"
RRDS_MASTER="${RRDS}/master"
RRDS_W1="${RRDS}/worker1"
RRDS_W2="${RRDS}/worker2"
RRDS_W3="${RRDS}/worker3"
RRDS_W4="${RRDS}/worker4"
RRDS_W5="${RRDS}/worker5"
RRDS_W6="${RRDS}/worker6"
RRDS_W7="${RRDS}/worker7"
RRDS_W8="${RRDS}/worker8"
MASTER_METRICS=(bytes_in.rrd bytes_out.rrd mem_buffers.rrd mem_cached.rrd mem_free.rrd cpu_idle.rrd cpu_system.rrd cpu_steal.rrd cpu_user.rrd cpu_wio.rrd)
WORKER_METRICS=(bytes_in.rrd bytes_out.rrd mem_buffers.rrd mem_cached.rrd mem_free.rrd cpu_idle.rrd cpu_system.rrd cpu_steal.rrd cpu_user.rrd cpu_wio.rrd)


DIM=$1  #get the dimensions as the first argument passed to the script
CHUNKS=$2  #number of partitions for the input file of spark job
POINTS=$3 #number of points in the dataset
RES_DIR="/opt/Spark_jobs/9vms_2cores_4GBram/ds${POINTS}/dim${DIM}" #the directory of the jobs for 10.000 data points
SPARK_HOME="/opt/spark-1.2.0-bin-hadoop2.4"
SPARK_SUBMIT="${SPARK_HOME}/bin/spark-submit"
APP_DIR="${SPARK_HOME}/apps"
HDFS_DIR="/kmeans/n${POINTS}/d${DIM}/n${POINTS}d${DIM}"

SPARK_KMEANS="$APP_DIR/sparktest.py"

function makefiles {
    #function to create the files if they are not already created
    [ -e "$JOB_DIR/stdout" ] || touch $JOB_DIR/stdout  #stdout file for spark-submit
    [ -e "$JOB_DIR/stderr" ] || touch $JOB_DIR/stderr  #stderr file for spark-submit
    [ -e "$JOB_DIR/time" ] || touch $JOB_DIR/time #file to report execution time
    #[ -e "$APP_DIR/script_output"] || touch $APP_DIR/script_output #output file for the current script
    return
}

function makedirs {
    for node in master worker1 worker2 worker3 worker4 worker5 worker6 worker7 worker8
    do
        [ -d "$JOB_DIR/$node" ] || mkdir $JOB_DIR/$node #create the directories for the metrics of ganglia
    done
    return        
}

function start_iostats {
    #start iostat over ssh to all nodes in the cluster
    for w in {1..8}
    do
        ssh worker${w} "nohup iostat -dm 5 >/root/iostat_unformatted &"
    done
    return
}

function stop_iostats {
    for si in {1..8}
    do
        ssh worker${si} "pkill -f iostat"
    done
    return
}

function fetch_iostats {
    for f in {1..8}
    do
        scp worker${f}:/root/iostat_unformatted $JOB_DIR/worker${f}/
        sed -n '7~3p' $JOB_DIR/worker${f}/iostat_unformatted | tr -s ' ' ',' >$JOB_DIR/worker${f}/iostat_csv
    done
    return
        
}



function report_time {
    STRING_START_TIME="`date -d@$JOB_START_TIME`"  #job start time in human readable format
    STRING_STOP_TIME="`date -d@$JOB_END_TIME`" #job end time in human readable format
    TIME_DIF="$[$JOB_END_TIME-$JOB_START_TIME]"
    echo "$JOB_START_TIME,$STRING_START_TIME" >$JOB_DIR/time
    echo "$JOB_END_TIME,$STRING_STOP_TIME" >>$JOB_DIR/time
    echo "$TIME_DIF" >>$JOB_DIR/time
    return
}

function place_event {
    #use of the ganglia event api 
    res=`curl "http://master/ganglia/api/events.php?action=add&start_time=${GANGLIA_EVENT_START}&summary=${JOB_NAME}&host_regex=*&end_time=${GANGLIA_EVENT_STOP}" 2>/dev/null`
    echo "[+] Just placed an event in ganglia for the job" >>$APP_DIR/script_output
    return
}

function gather_metrics {
    #fetch the metrics for the master first excluding the disk IOs
    for METRIC in ${MASTER_METRICS[*]}
    do
        rrdtool fetch ${RRDS_MASTER}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/master/${METRIC%.*}"
    done
    #fetch the metrics for all the worker nodes
    for METRIC in ${WORKER_METRICS[*]}
    do
        rrdtool fetch ${RRDS_W1}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker1/${METRIC%.*}"
        rrdtool fetch ${RRDS_W2}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker2/${METRIC%.*}"
        rrdtool fetch ${RRDS_W3}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker3/${METRIC%.*}"
        rrdtool fetch ${RRDS_W4}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker4/${METRIC%.*}"
        rrdtool fetch ${RRDS_W5}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker5/${METRIC%.*}"
        rrdtool fetch ${RRDS_W6}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker6/${METRIC%.*}"
        rrdtool fetch ${RRDS_W7}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker7/${METRIC%.*}"
        rrdtool fetch ${RRDS_W8}/${METRIC} AVERAGE --start $GANGLIA_EVENT_START --end $GANGLIA_EVENT_STOP >"${JOB_DIR}/worker8/${METRIC%.*}"
    done
    return
}

function clear_caches {
	for cc in {1..8}
	do
		ssh worker${cc} "sync; echo 3 >/proc/sys/vm/drop_caches"
	done
	return
}


#for every dataset with different centroid run spark-submit with the appropriate command line arguments
#for every possible number of iterations
COUNTER=0
for i in 10 #40 60 80 100
do
    #loop over the different versions
	for v in 0 #1
	do
	    #loop over the different clusters
	    for c in 100 500 1000 #10 100 200 300 400 500 600 700 800 900 1000 1200 1400 1600
	    do
            JOB_DIR="${RES_DIR}/clus${c}/iter${i}"  #keep the directory of the current job in a variable
            echo -e "\t\tSTART OF SCRIPT OUTPUT No$((COUNTER++))" >$APP_DIR/script_output
            makefiles
            makedirs
	    echo "[+] Clearing caches in all nodes..." >>$APP_DIR/script_output
	    #clear_caches
            echo "[+] Created the files and directories for the job" >>$APP_DIR/script_output
	    [ -e "$JOB_DIR/master/master_iostat_unformatted" ] || touch $JOB_DIR/master/master_iostat_unformatted  #the file with the iostat statistics for the master node only
	    echo "[+] Created the master_iostat_unformatted file" >>$APP_DIR/script_output
	    echo "[+] Launching master iostat job in the background..." >>$APP_DIR/script_output
	    iostat -dm 5 >$JOB_DIR/master/master_iostat_unformatted &
	    IOSTAT_PID=$! #saving the pid of the iostat process
	    echo "[+] Launching iostat processes on all nodes remotely.." >>$APP_DIR/script_output
	    start_iostats
	    echo "[+] Iostat processes just started.." >>$APP_DIR/script_output
	    echo "[+] Sleeping for 30 secs..." >>$APP_DIR/script_output
	    GANGLIA_EVENT_START=`date +%s` #event start timestamp
	    sleep 30 # give some time to iostat to collect the first metrics
	    JOB_NAME="Spark_n${POINTS}_d${DIM}_c${c}_i${i}"  # the name of the job about to run
	    #JOB_NAME="full_run_test"
	    echo "[+] Submitting job to spark..." >>$APP_DIR/script_output
	        
	    $SPARK_SUBMIT --conf spark.executor.memory=2700m $SPARK_KMEANS $JOB_NAME $HDFS_DIR $i $c $CHUNKS >$JOB_DIR/stdout 2>$JOB_DIR/stderr &
	    SPARK_SUBMIT_PID=$! #saving the pid of spark submit script running in the background
	    # wait until the spark spits the first stderr line in the file
	    while [ "`wc -l $JOB_DIR/stderr`" = "0 $JOB_DIR/stderr" ]; do
	        continue
	    done
	    JOB_START_TIME=`date +%s` #current job start timestamp
	        
	    wait $SPARK_SUBMIT_PID  #now wait for the job to complete
	    JOB_END_TIME=`date +%s` #current job stop timestamp
	    echo "[+] Job: $JOB_NAME just ended" >>$APP_DIR/script_output
	    echo "[+] Sleeping for 45 secs..." >>$APP_DIR/script_output
	    sleep 45
	    GANGLIA_EVENT_STOP=`date +%s` #event stop timestamp
	    echo "[+] Killing master iostat process..." >>$APP_DIR/script_output
	    kill -SIGTERM $IOSTAT_PID
	    echo "[+] Killing iostat processes on all workers.." >>$APP_DIR/script_output
	    stop_iostats
	    echo "[+] Reporting time statistics for the job" >>$APP_DIR/script_output
	    report_time #report time stats for the job p in the appropriate file
	    echo "[+] Placing an event to ganglia" >>$APP_DIR/script_output
	    place_event
	        
	    echo "[+] Starting to gather all the metrics and formatting the iostat outputs for all nodes..." >>$APP_DIR/script_output
	    sed -n '7~3p' $JOB_DIR/master/master_iostat_unformatted | tr -s ' ' ',' >$JOB_DIR/master/master_iostat_csv
	    fetch_iostats
	    gather_metrics
	    echo "[+] Metrics from ganglia for all nodes where gathered" >>$APP_DIR/script_output
	    echo "[+] Half minute pause before continuing with the next job..." >>$APP_DIR/script_output
	    echo "[+] All ok" >>$APP_DIR/script_output
	    sleep 30
	    done #end of cluster iterations
	done #end of version iterations
done #end of iter iterations



