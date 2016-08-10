#!/bin/bash

# Example script to run a workload.

YCSB_HOME=.
if [ $# -lt 4 ] ; then
	SCRIPT_NAME=`basename $0`
    echo "USAGE:  $SCRIPT_NAME {load | t} {number of threads} {workload file in $YCSB_HOME/workloads} {map | queue}"
    exit
fi

java \
-Ddebug=true \
-Xmx1024M \
-Dhazelcast.super.client=true \
-cp ${YCSB_HOME}/build/ycsb.jar:${YCSB_HOME}/db/hazelcast/lib/hazelcast-1.8.5/lib/hazelcast-1.8.5.jar:${YCSB_HOME}/db/hazelcast/lib/hazelcast-1.8.5/bin \
com.yahoo.ycsb.Client \
-${1} \
-threads ${2} \
-db com.yahoo.ycsb.db.HazelcastClient \
-p measurementtype=histogram \
-p hc.dataStructureType=${4} \
-p hc.queuePollTimeoutMs=2000 \
-p hc.async=true \
-p hc.asyncTimeoutMs=50 \
-P ${YCSB_HOME}/workloads/${3}


