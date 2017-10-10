KV-replay - Benchmarking Key-Value Stores via Trace Replay
==========================================================
Overview
--------
KV-replay is a project to extend the Yahoo! Cloud System Benchmark (YCSB) by including the option to reproduce a realistic workload by reading a file of traces.

### Links about Yahoo! Cloud System Benchmark (YCSB)
Information and source code for the Yahoo! Cloud System Benchmark (YCSB) project can be found in the following links:

+ http://wiki.github.com/brianfrankcooper/YCSB/  
+ https://github.com/brianfrankcooper/YCSB/

Getting Started
---------------

1. Clone this repository:

    ```sh
    git clone https://github.com/ebozag/KV-replay.git
    cd KV-replay/
    ```
    
2.  Build from source

    To build the full distribution, with all database bindings:

    ```sh
    mvn clean package
    ```

    To build a single database binding:

    ```sh
    mvn -pl com.yahoo.ycsb:redis-binding -am clean package
    ```

3. Set up a database to benchmark. There is a README file under each binding directory.

4. Set up the configuration file for KV-replay. There is a template configuration file in **workloads/workload-replay_template**. The basic configuration lines, for full-speed and closed-loop model, are:

   ```
   workload=com.yahoo.ycsb.workloads.ReplayWorkload
   tracefile=workloads/<trace filename>
   ```
5. Run KV-replay command (example for Redis database in localhost). 
    
    ```sh
    bin/kv-replay run redis -P workloads/workload-replay_template -p "redis.host=127.0.0.1" -p "redis.port=6379"
    ```

Additional Configurations
-------------------------

### Read Object Sizes from Trace

To read the size for each object from the tracefile, use the following workload configuration property:

   ```sh
   sizefromtrace=true
   ```

Size will be read in *bytes* from the 4th column on the comma-separated formated trace file.


### Read Arrival Times from Trace

To read the arrival time for each request from the tracefile, use the following workload configuration properties:

   ```sh
   withtimestamp=true
   timestampfactor=1
   ```
- If *withtimestamp* is set to *FALSE* (default), the requests will be send at full speed, one after the other.
- *timestampfactor* property is used as a conversion factor for the timestamp read from the trace. For example, it should be set to *1* (default) when timestamps in the trace are in miliseconds, or should be set to *1000* when timestamps are expressed in seconds.

### Replay Model

Replay model is defined by the dependency between events. In the *Open Loop Model*, events are independent from each other, and can be issued without any constraints linked to the previous request. In the *Closed Loop Model*, an event is issued only after the previous request has been completed. The **workload** property in the configuration file is used to define the replay model for KV-replay.

To select the *closed* loop model, use the following line in the configuration file:

   ```
   workload=com.yahoo.ycsb.workloads.ReplayWorkload
   ```

Otherwise, to select the *open* loop model, use the following configuration:

   ```
   workload=com.yahoo.ycsb.workloads.ReplayWorkloadScheduledMulti
   ```

### Temporal Scaling

Temporal scaling is a feature to scale out/down the interarrival times in the realistic workload. To adjust the temporal scaling, use the following workload configuration property:

   ```sh
   temporalscaling=1
   ```
- If *temporalscaling* is set to a value less than 1, the interarrival times will be decreased, incrementing the pressure on the DB.
- If *temporalscaling* is set to a value greater than 1, the interarrival times will be increased, and the pressure on the DB will be reduced.
- Defaul value for *temporalscaling* property is 1.

This feature is currently supporte only with the *ReplayWorkloadScheduledMulti* class (Open Loop Model).

    
### Running multiple replayer instances

When replaying heavy workloads, it could be necesary to split it into multiple instances in order to keep the timing accuracy. There are 3 properties needed to coordinately run multiple instances of the KV-replay with a single workload:

- *startdatetime*, considered as an start barrier, will define the exact time where the replay will start dispatching requests. The date/time required format for this property is: "2016-01-01 00:00:00:000"
- *instances*, defines the number of replayer instances to be used. 
- *instanceid*, allows to identify the replayer instance in order to read and dispatch the corresponding records from the trace.

Please note that each of the replayer instances must have its own KV-replay folder, including the tracefile. For example, to execute 3 instances of the replayer with a (fictional) tracefile:

   ```sh
   cd KV-replay-1
   bin/kv-replay run redis -P workloads/workload-replay_template -p "redis.host=127.0.0.1" -p "redis.port=6379" -p "instances=3" -p "instanceid=1" -p startdatetime="2016-01-01 00:00:00:000" &
   cd ..

   cd KV-replay-2
   bin/kv-replay run redis -P workloads/workload-replay_template -p "redis.host=127.0.0.1" -p "redis.port=6379" -p "instances=3" -p "instanceid=2" -p startdatetime="2016-01-01 00:00:00:000" &
   cd ..

   cd KV-replay-3
   bin/kv-replay run redis -P workloads/workload-replay_template -p "redis.host=127.0.0.1" -p "redis.port=6379" -p "instances=3" -p "instanceid=3" -p startdatetime="2016-01-01 00:00:00:000" &
   cd ..
   ```

Acknowledgements
-----------------

This work was funded in part by a Google Faculty Research Award awarded to [Cristina L. Abad](https://sites.google.com/site/cristinaabad/)


Referencing our work
--------------------
If you found our tool useful and use it in research, please cite our work as follows:

*Edwin F. Boza, César San-Lucas, Cristina L. Abad, José A. Viteri, "Benchmarking key-value stores via trace replay". In Proceedings of the IEEE International Conference on Cloud Engineering (IC2E), 2017. Code available at: https://github.com/ebozag/KV-replay
