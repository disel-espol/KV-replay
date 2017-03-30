# Spatial Scaling

For many purposes is important to scale up or down a trace. Sometimes we do not have enough trace files for our evaluations, or we could need to increase/decrease the pressure on the target system. To spatially scale our trace KV-replay provides three shell scripts (Bash), each of them providing a different scaling aproach. *Cloning* and *intensifying* scripts scale-up the original trace. *Subtracing* script scales-down the original trace. Each of them will produce a new tracefile based in the input trace.

## Format of the input trace

These three scripts require a CSV tracefile with the same format as expected by KV-replay:

```sh
<Command, Object ID, Timestamp, Size>
```
For example:
```
READ,1bhOE7xcZyg,1201639757.082532,965
READ,3TKi92CP-vc,1201639761.780669,2
READ,1bhOE7xcZyg,1201639762.360242,965
...
```

## Clone Scaling

Cloning is one of the ways to scale up the trace . For that it takes the original input trace and for each record, the script makes *n* copies of it, depending on the number of copies the user want. Each key of the record is changed so they become unique. Is important to notice that the original operation, timestamp and object size remain the same for each new copy. The output trace will have *n* times the amount of records of the original trace.

### How to use the script

The script requires **3** parameters. The first parameter is the name of the **original tracefile** to be sccaled, the second parameter is the **number of copies** we want to made, and the third  parameter is the **name of the output file** that will be generated. 

### Example
```
./cloneScript.sh originalTraceFile.dat 4 originalTraceFile-scaled4times.dat
```

## SubTracing Scaling

### Explanation

Subtracing is a way in which we can scale down a trace. To accomplish that these script divides the original trace in n subtraces in which n is the numbers of divisons the user wants. The script then will generate n files , in which each of them is a subtrace with references to unique objects. That means that the references to one object will only remain in one of the subtraces. The sum of the records of all the subtraces will have the same amount of records as the original trace.


### Description of how to use the script

The script has 3 **parameters** to enter. The first is the **original trace file** that we want to scale, the second is the **number of subtraces** we want to made.

The third is a an optional value that **defines the way in which the algorithm work**. To define the subtraces the script use the keys of the trace and transform each of them into numbers. These parameter define the way that key is converted to a number. For that there are defined the values that these parameter can have: **sha, md5, tr, onlynumbers and ascii**. And each of them have different time performances. The order of time performance from best to worst is : onlynumbers, md5 , sha , tr and finally ascii. The variance of registries in each trace is nearly the same * . Is important to notice that parameter value only numbers only works when the trace keys are numbers. Also ascii works when the keys are composed by ascii characters and tr when keys are composed by alphanumeric characters or/and the symbols @%-_ . Default value is md5 .

After the trace is executed it will print the name of each subtrace, the number of records each of one has, and also the amount of objects that references each trace.

The name of each subtrace will have the next **format**:
```
$inputTrace-subtrace-$number-of-$numberOfSubtraces-method-$typeAlgorithm
```
where 
<br>
**$inputTrace** is the input original trace.
<br>
**$number** the corresponding number of the subtrace.
<br>
**$numberOfSubtraces** is the total of subtraces.
<br>
**$typeAlgorithm** is the algorithm selected.

### Example of use

**1**
```
./subTracingScript.sh traceExample.dat 4
```
Would generate 4 traces using the md5 method. And it will print the name of the output subtraces, the corresponding records of each of them, and also the amount of objects that references each trace.

```
 the subtrace : traceExample.dat-subtrace-1-of-4-method-md5 has 243 records , for 186 objects
 the subtrace : traceExample.dat-subtrace-2-of-4-method-md5 has 249 records , for 191 objects
 the subtrace : traceExample.dat-subtrace-3-of-4-method-md5 has 282 records , for 190 objects
 the subtrace : traceExample.dat-subtrace-4-of-4-method-md5 has 226 records , for 185 objects
```


**2**
```
./subTracingScript.sh traceExample.dat 4 sha
```
Would generate 4 traces using sha. And it will print the name of the output subtraces, the corresponding records of each of them, and also the amount of objects that references each trace.

```
 the subtrace : traceExample.dat-subtrace-1-of-4-method-sha has 266 records , for 201 objects
 the subtrace : traceExample.dat-subtrace-2-of-4-method-sha has 265 records , for 199 objects
 the subtrace : traceExample.dat-subtrace-3-of-4-method-sha has 255 records , for 174 objects
 the subtrace : traceExample.dat-subtrace-4-of-4-method-sha has 214 records , for 178 objects
```

## Intensifying Scaling

### Explanation

Intensifying is a way to scale up a trace. The objective of these method is to generate a trace with the same amount of records and keys as the original but **temporally and spatially scaled**. To accomplish that the original trace is divided in subtraces that are aligned at time 0 and merged to create an illusion of concurrency , in which a record of the subtrace N is replayed after a record of the subtrace N-1. The numbers of subtraces created and originated is also called **TIF** acronym of **trace intensifying factor**. The timestamps between records is also compressed in a factor proportional to the number of subtraces present. Is important to say that the subtraces obtained with these method are not the same that the ones obtained with the subtracing script.

### Description of how to use the script

The script has 3 **parameters** to enter. The first is the **original trace file** that we want to scale, the second is the **TIF** we want to made, where TIF means trace intensifying factor , these is the number of subtraces generated and merged. The third is the **name of the output file** that will be generated.


The output trace will have the **same number of records** as the original, but the records will be in order. That means that after a subtrace n record will follow a record part of the subtrace n+1 . That until it reachs a record part of the last subtrace, in that case the record that will follow it is some record part of the subtrace 1. The timestamps also will be compressed. 

### Example of use 

**1**
```
./intensifyingScript.sh traceExample.dat 4 traceOutput.dat
```
That would generate an intenseTrace with a TIF=4 named traceOutput.dat originated from the trace named traceExample.dat.





