package com.yahoo.ycsb.db;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.Vector;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.locks.ReentrantLock;

import com.hazelcast.core.Hazelcast;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.core.IMap;
import com.hazelcast.client.config.ClientConfig;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.StringByteIterator;

/**
 * 
 * @author ypai
 * 
 */
public class HazelcastClient extends DB {

    private static final int MAP = 1;
    private static final int QUEUE = 2;

    private static final ReentrantLock _lock = new ReentrantLock();

    private boolean debug = false;
    private boolean superclient = false;
    private int dataStructureType = 1;

    private int pollTimeoutMs = 50;

    private static HazelcastInstance _client;

    private boolean async = false;
    private int asyncTimeoutMs = 50;

    private static boolean infoEchoed = false;

    private HashMap<String, IMap<String, Map<String, String>>> mapMap = new HashMap<String, IMap<String, Map<String, String>>>();
    private HashMap<String, BlockingQueue<Map<String, String>>> queueMap = new HashMap<String, BlockingQueue<Map<String, String>>>();

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#init()
     */
    @Override
    public void init() throws DBException {
        super.init();
        if (System.getProperty("debug") != null) {
            this.debug = true;
        }
        Properties conf = this.getProperties();

        // check for async
        this.async = "true".equals(conf.getProperty("hc.async"))
                || "1".equals(conf.getProperty("hc.async"));
        String asyncTimeoutMs = conf.getProperty("hc.asyncTimeoutMs");
        if (asyncTimeoutMs != null) {
            this.asyncTimeoutMs = Integer.parseInt(asyncTimeoutMs);
        }

        // check for datastructure type
        String dataStructureType = conf.getProperty("hc.dataStructureType");
        if ("queue".equalsIgnoreCase(dataStructureType)) {
            this.dataStructureType = QUEUE;

            String pollTimeoutMs = conf.getProperty("hc.queuePollTimeoutMs");
            if (pollTimeoutMs != null) {
                this.pollTimeoutMs = Integer.parseInt(pollTimeoutMs);
            }

        } else if ("map".equalsIgnoreCase(dataStructureType)) {
            this.dataStructureType = MAP;

        } else {
            log("error", "Unknown data structure type:  " + dataStructureType
                    + "; please specify with 'hc.dataStructureType' property!",
                    null);
            System.exit(1);
        }

        // check if we are using superclient mode
        this.superclient = "true".equals(System
                .getProperty("hazelcast.super.client"));

        // not using superclient mode, so set up java client
        if (!superclient) {
            _lock.lock();
            try {
                if (_client == null) {
                    log("info", "Initializing Java client...", null);
                    String groupName = conf.getProperty("hc.groupName");
                    String groupPassword = conf.getProperty("hc.groupPassword");
                    String address = conf.getProperty("hc.address");
                    if (address == null) {
                        log(
                                "error",
                                "No cluster address specified for client!  Use 'hc.address'!",
                                null);
                        System.exit(1);
                    }
		    
		    ClientConfig clientConfig = new ClientConfig();
	            clientConfig.addAddress(address);

                    _client = com.hazelcast.client.HazelcastClient.newHazelcastClient(clientConfig);

                    /*_client = com.hazelcast.client.HazelcastClient
                            .newHazelcastClient(groupName, groupPassword,
                                    address);*/

                }
            } catch (Exception e1) {
                log("error", "Could not initialize Hazelcast Java client:  "
                        + e1, e1);
                System.exit(1);
            } finally {
                _lock.unlock();
            }
        }

        // write out what/how client is testing to STDOUT
        _lock.lock();
        try {
            if (!this.infoEchoed) {
                if (this.debug) {
                    log("info",
                            "Debug mode:  using data structure name 'default'",
                            null);
                }
                if (this.superclient) {
                    log("info", "Using super client", null);
                } else {
                    log("info", "Using Java client", null);
                }

                log("info", "Testing data structure type:  "
                        + dataStructureType, null);

                log("info", "Queue poll timeout=" + this.pollTimeoutMs, null);

                if (this.async) {
                    log("info",
                            "Will do asynchronous puts when using MAP:  timeout="
                                    + this.asyncTimeoutMs, null);
                }
                this.infoEchoed = true;
            }
        } finally {
            _lock.unlock();
        }
    }

    protected IMap<String, Map<String, String>> getMap(String table) {
        IMap<String, Map<String, String>> retval = this.mapMap.get(table);

        if (retval == null) {
            if (this.superclient) {
                //retval = Hazelcast.getMap(table);
                retval = _client.getMap(table);
            } else {
                retval = _client.getMap(table);
            }
            this.mapMap.put(table, retval);
        }
        return retval;
    }

    protected BlockingQueue<Map<String, String>> getQueue(String table) {
        BlockingQueue<Map<String, String>> retval = (BlockingQueue<Map<String, String>>) this.queueMap
                .get(table);
        if (retval == null) {
            if (this.superclient) {
                //retval = Hazelcast.getQueue(table);
                retval = _client.getQueue(table);
            } else {
                retval = _client.getQueue(table);
            }
            this.queueMap.put(table, retval);
        }
        return retval;
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#delete(java.lang.String, java.lang.String)
     */
    @Override
    public int delete(String table, String key) {
        if (debug)
            table = "default";
        try {
            switch (this.dataStructureType) {
            case MAP:
                ConcurrentMap<String, Map<String, String>> distributedMap = getMap(table);
                distributedMap.remove(key);
                break;
            }
        } catch (Exception e1) {
            log("error", e1 + "", e1);
            return 1;
        }
        return 0;
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#insert(java.lang.String, java.lang.String,
     * java.util.HashMap)
     */
    @Override
    //public int insert(String table, String key, HashMap<String, String> values) {
    public int insert(String table, String key, HashMap<String, ByteIterator> valuesByteIterator) {
	HashMap<String, String> values = new HashMap<String, String>();
	StringByteIterator.putAllAsStrings(values, valuesByteIterator);
        if (debug)
            table = "default";
        try {
            switch (this.dataStructureType) {
            case MAP:
                IMap<String, Map<String, String>> distributedMap = getMap(table);
                if (this.async) {
                    try {
                        Future<Map<String, String>> future = distributedMap
                                .putAsync(key, values);
                        future.get(this.asyncTimeoutMs, TimeUnit.MILLISECONDS);
                    } catch (TimeoutException t) {
                        // time wasn't enough
                    }
                } else {
                    distributedMap.put(key, values);
                }
                break;
            case QUEUE:
                BlockingQueue<Map<String, String>> distributedQueue = getQueue(table);
                if (!distributedQueue.offer(values)) {
                    throw new RuntimeException("Unable to insert into queue!");
                }
                break;
            }
        } catch (Exception e1) {
            log("error", e1 + "", e1);
            return 1;
        }
        return 0;
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#read(java.lang.String, java.lang.String,
     * java.util.Set, java.util.HashMap)
     */
    @Override
    public int read(String table, String key, Set<String> fields,
            HashMap<String, ByteIterator> resultByteIterator) {
        HashMap<String, String> result = new HashMap<String, String>();
        StringByteIterator.putAllAsStrings(result, resultByteIterator);

	int returnCode = 0;
        if (debug)
            table = "default";
        try {
            switch (this.dataStructureType) {
            case MAP:
                ConcurrentMap<String, Map<String, String>> distributedMap = getMap(table);
                Map<String, String> resultMap = distributedMap.get(key);
                if (resultMap != null) {
                    //log("info", "resultMap not null", null);
                    //log("info", resultMap.toString(), null);
                    result.putAll(resultMap);
                    StringByteIterator.putAllAsByteIterators(resultByteIterator,result);
		} else{
                    //log("info", "resultMap IS null", null);
		    returnCode=1;
		}
		//result.putAll(resultMap);
                break;
            case QUEUE:
                BlockingQueue<Map<String, String>> distributedQueue = getQueue(table);
                resultMap = distributedQueue.poll(this.pollTimeoutMs,
                        TimeUnit.MILLISECONDS);
                if (resultMap != null)
                    result.putAll(resultMap);
                break;
            }
        } catch (Exception e1) {
            log("error", e1 + "", e1);
            return 1;
        }
        return returnCode;
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#scan(java.lang.String, java.lang.String, int,
     * java.util.Set, java.util.Vector)
     */
    @Override
    public int scan(String table, String startkey, int recordcount,
            Set<String> fields, Vector<HashMap<String, ByteIterator>> result) {
        throw new UnsupportedOperationException(
                "scan() is not supported at this time!");
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.yahoo.ycsb.DB#update(java.lang.String, java.lang.String,
     * java.util.HashMap)
     */
    @Override
    //public int update(String table, String key, HashMap<String, String> values) {
    public int update(String table, String key, HashMap<String, ByteIterator> valuesByteIterator) {
        HashMap<String, String> values = new HashMap<String, String>();
        StringByteIterator.putAllAsStrings(values, valuesByteIterator);

        if (debug)
            table = "default";
        try {
            switch (this.dataStructureType) {
            case MAP:
                IMap<String, Map<String, String>> distributedMap = getMap(table);
                if (values != null && values.size() > 0) {
                    Map<String, String> resultMap = distributedMap.get(key);
                    Iterator<String> iter = values.keySet().iterator();
                    String k = null;
                    while (iter.hasNext()) {
                        k = iter.next();
                        resultMap.put(k, values.get(k));
                    }
                    if (this.async) {
                        try {
                            Future<Map<String, String>> future = distributedMap
                                    .putAsync(key, values);
                            future.get(this.asyncTimeoutMs,
                                    TimeUnit.MILLISECONDS);
                        } catch (TimeoutException t) {
                            // time wasn't enough
                        }
                    } else {
                        distributedMap.put(key, resultMap);
                    }
                }
                break;
            }
        } catch (Exception e1) {
            log("error", e1 + "", e1);
            return 1;
        }
        return 0;
    }

    /**
     * Simple logging method.
     * 
     * @param level
     * @param message
     * @param e
     */
    protected void log(String level, String message, Exception e) {
        message = Thread.currentThread().getName() + ":  " + message;
        System.out.println(message);
        if ("error".equals(level)) {
            System.err.println(message);
        }
        if (e != null) {
            e.printStackTrace(System.out);
            e.printStackTrace(System.err);
        }
    }

}
