#This script is made to sum up a report for a kmeans job submitted to Weka
#It depends on metricsparser.py and memparser.py scripts 

function parse_memory {
    echo -n "" >$PARSED/cluster_mem
    for w in master worker1 worker2 worker3 worker4 worker5 worker6 worker7 worker8
    do
        #parse with metricsparser.py
        $METRICSPARSER $BASE_DIR/$w/mem_cached $BASE_DIR/$w/mem_cached1
        $METRICSPARSER $BASE_DIR/$w/mem_free $BASE_DIR/$w/mem_free1
        $METRICSPARSER $BASE_DIR/$w/mem_buffers $BASE_DIR/$w/mem_buffers1
        #create all tmp files inside every folder
        cut -d',' -f2 $BASE_DIR/$w/mem_free1 > $BASE_DIR/$w/mem_free_tmp
        cut -d',' -f2 $BASE_DIR/$w/mem_cached1 > $BASE_DIR/$w/mem_cached_tmp
        cut -d',' -f2 $BASE_DIR/$w/mem_buffers1 > $BASE_DIR/$w/mem_buffers_tmp
        #chop the first 3 lines and the last two from the file
        head -n -2 $BASE_DIR/$w/mem_free_tmp | tail -n +3 > $BASE_DIR/$w/mem_free_tmp1
        head -n -2 $BASE_DIR/$w/mem_cached_tmp | tail -n +3 > $BASE_DIR/$w/mem_cached_tmp1
        head -n -2 $BASE_DIR/$w/mem_buffers_tmp | tail -n +3 > $BASE_DIR/$w/mem_buffers_tmp1
        #create mem_all file in every folder 
        paste -d"," $BASE_DIR/$w/mem_free_tmp1 $BASE_DIR/$w/mem_cached_tmp1 $BASE_DIR/$w/mem_buffers_tmp1 > $BASE_DIR/$w/mem_all
        #parse with memparser.py
        $MEMPARSER $BASE_DIR/$w/mem_all $BASE_DIR/$w/average_mem_used
        #remove everything tmp created
        rm -f $BASE_DIR/$w/{mem_cached1,mem_free1,mem_buffers1}
        rm -f $BASE_DIR/$w/{mem_buffers_tmp,mem_cached_tmp,mem_free_tmp}
        rm -f $BASE_DIR/$w/{mem_buffers_tmp1,mem_cached_tmp1,mem_free_tmp1}
        #report mem_metric to cluster_mem file
        cat $BASE_DIR/$w/average_mem_used >>$PARSED/cluster_mem
    done
    return
}

function parse_diskio {
    #rename the iostat file of master
    cp $BASE_DIR/master/master_iostat_csv $BASE_DIR/master/iostat_csv
    echo -n "" >$PARSED/cluster_diskio_in
    echo -n "" >$PARSED/cluster_diskio_out
    for x in master worker1 worker2 worker3 worker4 worker5 worker6 worker7 worker8
    do
        #parse iostat_csv of every node
        DISK_IO_IN=`cut -d',' -f5 $BASE_DIR/$x/iostat_csv | paste -sd+ | bc`
        DISK_IO_OUT=`cut -d',' -f6 $BASE_DIR/$x/iostat_csv | paste -sd+ | bc`
        echo $DISK_IO_IN > $BASE_DIR/$x/diskio_in
        echo $DISK_IO_OUT > $BASE_DIR/$x/diskio_out
        echo $DISK_IO_IN >> $PARSED/cluster_diskio_in
        echo $DISK_IO_OUT >> $PARSED/cluster_diskio_out
    done
    return
}

function parse_net {
    echo -n "" >$PARSED/cluster_net_in
    echo -n "" >$PARSED/cluster_net_out
    for j in master worker1 worker2 worker3 worker4 worker5 worker6 worker7 worker8
    do
        $METRICSPARSER $BASE_DIR/$j/bytes_in  $BASE_DIR/$j/bytes_in1
        $METRICSPARSER $BASE_DIR/$j/bytes_out $BASE_DIR/$j/bytes_out1
        
        cut -d',' -f2 $BASE_DIR/$j/bytes_in1 > $BASE_DIR/$j/bytes_in_tmp
        cut -d',' -f2 $BASE_DIR/$j/bytes_out1 > $BASE_DIR/$j/bytes_out_tmp
        
        head -n -2 $BASE_DIR/$j/bytes_in_tmp | tail -n +3 > $BASE_DIR/$j/bytes_in_tmp1
        head -n -2 $BASE_DIR/$j/bytes_out_tmp | tail -n +3 > $BASE_DIR/$j/bytes_out_tmp1
        
        NET_IN=$(paste -sd+ $BASE_DIR/$j/bytes_in_tmp1)
        NET_OUT=$(paste -sd+ $BASE_DIR/$j/bytes_out_tmp1)
        nl=$(wc -l < $BASE_DIR/$j/bytes_in_tmp1)
        AVE_NET_IN=$(echo "$NET_IN/$nl" | bc)
        nl=$(wc -l < $BASE_DIR/$j/bytes_out_tmp1)
        AVE_NET_OUT=$(echo "$NET_OUT/$nl" | bc)
        
        echo "$AVE_NET_IN" >>$PARSED/cluster_net_in
        echo "$AVE_NET_OUT" >>$PARSED/cluster_net_out
        
        rm -f $BASE_DIR/$j/{bytes_in1,bytes_out1}
        rm -f $BASE_DIR/$j/{bytes_in_tmp,bytes_out_tmp}
        #rm -f $BASE_DIR/$w/{bytes_in_tmp1,bytes_out_tmp1}
    done
    return
}


METRICSPARSER="./metricsparser.py"
MEMPARSER="./memparser.py"
for ds in 5 #dataset sizes
do
    for d in 10 50 100 250 500 750 1000  #dimensions
    do
        for c in 10 100 200 300 400 500 600 700 800 900 1000 1200 1400 1600 #clusters
        do
            for i in 10 #iterations
            do
                BASE_DIR="/opt/Spark_jobs/9vms_2cores_4GBram/ds${ds}/dim${d}/clus${c}/iter${i}"
                PARSED="$BASE_DIR/parsed"
                MODEL_DATA="$BASE_DIR/model_data"
                mkdir -p $MODEL_DATA
                mkdir -p $PARSED
                parse_memory
                
                tail -1 $BASE_DIR/time > $PARSED/time
                parse_diskio
                #parse_net
                
                POINTS=$(echo "10^$ds" | bc)
                DI=$(paste -sd+ $PARSED/cluster_diskio_in | bc)
                DO=$(paste -sd+ $PARSED/cluster_diskio_out | bc)
                M=$(paste -sd+ $PARSED/cluster_mem | bc)
                echo "data_points,dimensions,k,time" >$MODEL_DATA/time_data
                echo "$POINTS,$d,$c,`cat $PARSED/time`" >>$MODEL_DATA/time_data
                
                echo "data_points,dimensions,k,cluster_mem_used" >$MODEL_DATA/average_mem_data
                echo "$POINTS,$d,$c,$M" >>$MODEL_DATA/average_mem_data
                
                echo "data_points,dimensions,k,cluster_diskio_in" >$MODEL_DATA/diskio_in_data
                echo "$POINTS,$d,$c,$DI" >>$MODEL_DATA/diskio_in_data
                
                echo "data_points,dimensions,k,cluster_diskio_out" >$MODEL_DATA/diskio_out_data
                echo "$POINTS,$d,$c,$DO" >>$MODEL_DATA/diskio_out_data
            done
        done
    done 
done
