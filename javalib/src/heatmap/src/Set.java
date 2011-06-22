import java.awt.Rectangle;
import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.json.JSONArray;
import org.json.JSONObject;


public class Set {

    private String name;
    private ArrayList<Entity> entities;
    private HashMap<String, String> meta;
    private HashMap<String, double[]> set_entity_map;
    
    public Set(String name, HashMap<String, String> entity_values) {
        
        this.name = name;
        this.entities = new ArrayList<Entity>();
        this.set_entity_map = new HashMap<String, double[]>();
        
        java.util.Set<String> names =  entity_values.keySet();
       
        Iterator<String> keys = names.iterator();
        
        while (keys.hasNext()) {
            String entName = keys.next();  
            this.entities.add(new Entity(entName));
            

            if ("".equals(entity_values.get(entName))) {
                continue;
            }
            
            // get the membership value
            double[] membership_value = new double[1];
            membership_value[0] = new Double(entity_values.get(entName));
            this.set_entity_map.put(entName, membership_value);
        }      
        
    }
    
    public Set(JSONObject jsonObj) throws Exception {
                
        this.entities = new ArrayList<Entity>();
        this.meta = new HashMap<String, String>();
        this.set_entity_map = new HashMap<String, double[]>();

        this.name = jsonObj.getString("_name");
        
        JSONObject elements = jsonObj.getJSONObject("_elements");
        Iterator<String> keys = elements.keys();

        while (keys.hasNext()) {
            String entName = keys.next();  
            this.entities.add(new Entity(entName));
            

            if (elements.isNull(entName) || "".equals(elements.get(entName))) {
                continue;
            }
            
            // get the membership value
            double[] membership_value = new double[1];
            membership_value[0] = elements.getDouble(entName);
            this.set_entity_map.put(entName, membership_value);
        }
        
        JSONObject metas = jsonObj.getJSONObject("_metadata");
        Iterator<String> metaKeys = metas.keys();

        while (metaKeys.hasNext()) {
            String key = metaKeys.next();
            this.meta.put(key, metas.getString(key));
        }
            
    }
    
    
    public boolean contains(Entity entity) {
        
        if (this.entities.contains(entity)) {
            return true;
        }
        return false;
    }
    
    public double membershipValue(Entity entity) {
        if (this.set_entity_map.containsKey(entity.getValue())) {
            double[] value = this.set_entity_map.get(entity.getValue());
            return value[0];
        }
        if (!this.entities.contains(entity)) {
            return 0;
        }
        return 1;
        //return this.entities;
    }
    
    public ArrayList<Entity> getEntities() {
        return this.entities;
    }
    
    public String toString() {
        String newstr = new String("Elements: ");
        Iterator<Entity> iter = this.entities.iterator();
        while (iter.hasNext()) {
            newstr = newstr + ":" + ((Entity)iter.next()).toString();
        }
        
        ArrayList<String> metas = (ArrayList<String>) this.meta.keySet();
        Iterator<String> metaIter = metas.iterator();
        newstr = newstr + "Metas: ";
        while (metaIter.hasNext()) {
            String key = metaIter.next();
            newstr = newstr + ":" + key + "-val-" + this.meta.get(key);
        }
        return newstr;
    }
    
    public String getName() {
        return this.name;
    }
    
}
