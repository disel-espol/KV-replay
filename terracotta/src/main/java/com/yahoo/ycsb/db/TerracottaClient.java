package com.yahoo.ycsb.db;

import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.Vector;

import net.sf.ehcache.CacheManager;
import net.sf.ehcache.Ehcache;
import net.sf.ehcache.Element;

import com.yahoo.ycsb.ByteArrayByteIterator;
import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;


public class TerracottaClient extends DB {
    /** Return code when operation succeeded */
    private static final int SUCCESS = 0;

    public static final String CLEAR_BEFORE_PROP = "clearbeforetest";

    /** Return code when operation did not succeed */
    private static final int ERROR = -1;

    private static volatile Ehcache cache = null;

    @Override
    public void init() throws DBException {
        super.init();
        if (cache != null) {
            return;
        }
        synchronized (TerracottaClient.class) {
            if (cache != null) {
                return;
            }

            cache = CacheManager.newInstance().getEhcache("terraCache");
            cache.setStatisticsEnabled(true);

            Properties props = getProperties();
            if (props.getProperty(CLEAR_BEFORE_PROP, "false")
                    .equalsIgnoreCase("true")) {
                cache.removeAll();
            }
        }
    }
    
    @Override
    public int read(String table, String key, Set<String> fields, HashMap<String, ByteIterator> result) {
        Element valueElement = cache.get(key);
        if (valueElement == null) {
            return ERROR;
        }
        
        Map<String, byte[]> valMap = (Map<String, byte[]>) valueElement.getValue();
        if (valMap != null) {
            if (fields == null) {
                for (String fieldsKey : valMap.keySet()) {
                    result.put(fieldsKey, new ByteArrayByteIterator(valMap.get(fieldsKey)));
                }
            } else {
                for (String field : fields) {
                    result.put(field, new ByteArrayByteIterator(valMap.get(field)));
                }
            }
            return SUCCESS;
        }
        return ERROR;
    }

    @Override
    public int scan(String table, String startkey, int recordcount, Set<String> fields,
            Vector<HashMap<String, ByteIterator>> result) {
        return ERROR;
    }

    @Override
    public int update(String table, String key, HashMap<String, ByteIterator> values) {
        cache.put(new Element(key, convertToBytearrayMap(values)));
        return 0;
    }

    @Override
    public int insert(String table, String key, HashMap<String, ByteIterator> values) {
        update(table, key, values);
        return 0;
    }

    @Override
    public int delete(String table, String key) {
        cache.remove(key);
        return 0;
    }

    private Map<String, byte[]> convertToBytearrayMap(Map<String, ByteIterator> values) {
        Map<String, byte[]> retVal = new HashMap<String, byte[]>();
        for (String key : values.keySet()) {
            retVal.put(key, values.get(key).toArray());
        }
        return retVal;
    }

    @Override
    public void cleanup() throws DBException {
        System.out.println("***Cache hits:" + cache.getStatistics().getCacheHits());
        System.out.println("***Cache misses:" + cache.getStatistics().getCacheMisses());
        super.cleanup();
    }
    
}
