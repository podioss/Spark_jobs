# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ls='ls --color=auto'
alias vi='vim'
alias hadooph='cd /opt/hadoop-2.6.0/'
alias spark='cd /opt/spark-1.2.0-bin-hadoop2.4/'
alias test_workers='for i in 1 2 3 4 5 6 7 8; do ssh worker$i tail -1 /opt/spark-1.2.0-bin-hadoop2.4/logs/spark-root-org.apache.spark.deploy.worker.Worker-1-worker$i.novalocal.out; done'
alias bell='echo -ne "\007"'
alias sparkjobs='cd /opt/Spark_jobs'
alias wekajobs='cd /opt/Weka_jobs'

function start_gmonds {
	for i in {1..8}
	do
		ssh worker${i} "systemctl start gmond; systemctl status gmond | grep -i active"
	done
	return
}

function clear_spark_logs {
	for i in {1..8};do  ssh worker${i} "rm -rf /opt/spark-1.2.0-bin-hadoop2.4/logs/*" ; done
	rm -rf /opt/spark-1.2.0-bin-hadoop2.4/logs/*
	return
}

function clear_spark_work {
	for w in {1..8};do ssh worker${w} "rm -rf /opt/spark-1.2.0-bin-hadoop2.4/work/*" ; done
	return
}
#exports
export HADOOP_PREFIX="/opt/hadoop-2.6.0/"
export HADOOP_HOME=$HADOOP_PREFIX
export HADOOP_COMMON_HOME=$HADOOP_PREFIX
export HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop
export HADOOP_HDFS_HOME=$HADOOP_PREFIX
export HADOOP_MAPRED_HOME=$HADOOP_PREFIX
export HADOOP_YARN_HOME=$HADOOP_PREFIX
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.45-31.b13.fc21.x86_64/"
export PATH=$PATH:$HADOOP_PREFIX/bin
export PATH=$PATH:$HADOOP_PREFIX/sbin
export PATH=$PATH:/opt/spark-1.2.0-bin-hadoop2.4/bin
export PATH=$PATH:/opt/spark-1.2.0-bin-hadoop2.4/sbin
# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
