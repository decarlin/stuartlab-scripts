import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.Rectangle2D;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;



public class Grid {
    ArrayList<Column> columns;
    
    public Grid() {
        this.columns = new ArrayList<Column>();
    }
    
    public void addColumn(Column column) {
        this.columns.add(column);
    }
    
    public void paintGrid(Graphics2D g2, Color memberColor, Color neutral, Color antiMemberColor) {
        Iterator<Column> colIter = columns.iterator();
        while (colIter.hasNext()) {
            colIter.next().paintColumn(g2, memberColor, neutral, antiMemberColor);
        }        
    }
    
    public HashMap<String, ArrayList<String>> getSetsEntitiesForDimension(Rectangle2D.Double rect) {
        
        // well, duh
        
        double xstart = rect.getMinX();
        double xend = xstart + rect.getWidth();
        double ystart = rect.getMinY();
        double yend = ystart + rect.getHeight();
        
        ArrayList<String> sets = new ArrayList<String>();
        
        Iterator<Column> colIter = this.columns.iterator();
        while (colIter.hasNext()) {
            Column column = colIter.next();
            if (column.getIndex() >= xstart && column.getIndex() <= xend) {
                sets.add(column.getSetName());
            }
        }    
        
        // any column will do
        Column firstColumn = this.columns.get(0);
        ArrayList<String> entities = firstColumn.getEntitiesForDimension(ystart, yend);
        
        HashMap<String, ArrayList<String>> map = new HashMap<String, ArrayList<String>>();
        
        map.put("sets", sets);
        map.put("entities", entities);
        
        return map;
    }


}
