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

The script requires **3** parameters. The first parameter is the name of the **original tracefile** to be scaled, the second parameter is the **number of copies** we want to made, and the third  parameter is the **name of the output file** that will be generated. 

### Example
```
./cloneScript.sh originalTraceFile.dat 4 originalTraceFile-scaled4times.dat
```

## SubTracing Scaling

Subtracing is a way to scale-down a trace. This script divides the original trace in *n* subtraces, where *n* is is provided by te user. The script will generate *n* files, each of them containing a subtrace with references to unique objects. That means that the references to one object will only remain in one of the subtraces. The sum of the records of all the subtraces will have the same amount of records as the original trace.

### How to use the script

The script requires 3 **parameters**. The first parameter is the name of the **original tracefile** to be scaled, the second parameter is the **number of subtraces** to be made. The third parameter is an optional value that **hash** function to be used for the subtracing; the options are: **sha, md5, tr, onlynumbers and ascii**. Default value is *md5*.

Each of the hashing optiones have different performances. The performance order, from best to worst, is: onlynumbers, md5, sha, tr, and ascii. It is important to notice that the **only numbers** option, only works when the trace keys are numbers. Also **ascii** works when the keys are composed by ascii characters and **tr** when keys are composed by alphanumeric characters or/and the symbols @%-_ . 

After the trace is executed it will print the name of each subtrace, the number of records, and the count of unique objects.

The name of each subtrace will have the following **format**:
```
<inputTrace>-subtrace-<number>-of-<numberOfSubtraces>-method-<typeAlgorithm>
```
, where:
- **<inputTrace>** is the name of the input tracefile.
- **<number>** the corresponding number of the subtrace.
- **<numberOfSubtraces>** is the total of subtraces.
- **<typeAlgorithm>** is the selected hash algorithm.

### Examples:

**Example 1:**
```
./subTracingScript.sh traceExample.dat 4
```
Would generate **4* traces using the (default) **md5** hash method. And it will print the following lines:
```
 the subtrace : traceExample.dat-subtrace-1-of-4-method-md5 has 243 records , for 186 objects
 the subtrace : traceExample.dat-subtrace-2-of-4-method-md5 has 249 records , for 191 objects
 the subtrace : traceExample.dat-subtrace-3-of-4-method-md5 has 282 records , for 190 objects
 the subtrace : traceExample.dat-subtrace-4-of-4-method-md5 has 226 records , for 185 objects
```

**Example 2:**
```
./subTracingScript.sh traceExample.dat 4 sha
```
Would generate **4* traces using the **sha** hash method. And it will print the following lines:
```
 the subtrace : traceExample.dat-subtrace-1-of-4-method-sha has 266 records , for 201 objects
 the subtrace : traceExample.dat-subtrace-2-of-4-method-sha has 265 records , for 199 objects
 the subtrace : traceExample.dat-subtrace-3-of-4-method-sha has 255 records , for 174 objects
 the subtrace : traceExample.dat-subtrace-4-of-4-method-sha has 214 records , for 178 objects
```

## Intensifying Scaling

### Explanation

Intensifying is a way to scale up a trace. The objective of these method is to generate a trace with the same amount of records and keys as the original but **temporally and spatially scaled**. To accomplish that the original trace is divided in subtraces that are aligned at time 0 and merged to create an illusion of concurrency . The numbers of subtraces created and originated is also called **TIF** acronym of **trace intensifying factor**. Is important to say that the subtraces obtained with these method are not the same that the ones obtained with the subtracing script.

### Description of how to use the script

The script has 4 **parameters** to enter. The first is the **original trace file** that we want to scale, the second is the **TIF** we want to made, where TIF means trace intensifying factor , these is the number of subtraces generated and merged. The third is the **name of the output file** that will be generated. The fourth parameter is an **optional boolean parameter** that defines the way in which the subtraces are made. If is **true** the division of subtraces will be **by time**. If it is **false** the division of the subtraces will be by **the number of registers**. Each method is better explained in the paragraph below. **Default** value is **true**.


The division of subtraces by time divides the original trace that has a duration of **t time** in subtraces with **t/TIF
approximately duration each one**. In the same way ,division by number of subtraces will divide the original trace in **n** subtraces with **n/TIF records each one** . Is important to notice that in these particular method, the output trace **won't have the exactly same number of records** because the division in subtraces normally have a **residue** and that records are not count in the output trace. That means that if the original trace have **n** records and in the output trace there will be **st** merged subtraces, the output will have **st\*floor( st / 3)** records . For example if n=1000 and st=3 the output trace will have 999 records.

Both methods **merge the records** and put them in order **aligned at time zero**. The records in the output trace could be identified by subtrace because each record now has a **subtrace ID at the beggining**. 


### Example of use 

**1**
```
./intensifyingScript.sh traceExample.dat 4 traceOutput.dat
```
That would generate an intenseTrace with a TIF=4 named traceOutput.dat originated from the trace named traceExample.dat. The division in subtraces will be by time.

**2**
```
./intensifyingScript.sh traceExample.dat 4 traceOutput.dat false
```
That would generate an intenseTrace with a TIF=4 named traceOutput.dat originated from the trace named traceExample.dat. The division in subtraces will be by number or records.

**3**
```
./intensifyingScript.sh traceExample.dat 4 traceOutput.dat true
```
That would generate an intenseTrace with a TIF=4 named traceOutput.dat originated from the trace named traceExample.dat. The division in subtraces will be by time.





