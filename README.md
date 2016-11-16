KV-replay - Benchmarking Key-Value Stores via Trace Replay
==========================================================
Overview
--------
KV-replay is a project to extend the Yahoo! Cloud System Benchmark (YCSB) by including the option to reproduce a realistic workload by reading a file of traces.

###Links about Yahoo! Cloud System Benchmark (YCSB)
Information and source code for the Yahoo! Cloud System Benchmark (YCSB) project can be found in the following links:

http://wiki.github.com/brianfrankcooper/YCSB/  
https://github.com/brianfrankcooper/YCSB/

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
    mvn -pl com.yahoo.ycsb:mongodb-binding -am clean package
    ```

3. Set up a database to benchmark. There is a README file under each binding 
   directory.

4. Set up the configuration file for YSCB-replay. There is a template configuration file in workloads/workload-rp. The main configuration lines are:

   workload=com.yahoo.ycsb.workloads.ReplayWorkload
   tracefile=workloads/<trace filename>

5. Run YCSB-replay command. 
    
    ```sh
    bin/ycsb load basic -P workloads/workload-rp
    bin/ycsb run basic -P workloads/workload-rp
    ```

