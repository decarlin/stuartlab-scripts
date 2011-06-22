import java.util.Comparator;


public class EntityComparator implements Comparator {

    public int compare(Object o1, Object o2) {
        Entity e1 = (Entity)o1;
        Entity e2 = (Entity)o2;
        
        return e1.getNumOccurances() - e2.getNumOccurances();
    }
    
}
