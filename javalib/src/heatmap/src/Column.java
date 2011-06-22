import java.awt.Color;
import java.awt.Graphics2D;
import java.util.ArrayList;
import java.util.Iterator;


public class Column {

    private double index;
    private String setName;
    // order matters
    private ArrayList<Cell> cells;
    
    public Column(double columnIndex, String name) {
        this.index = columnIndex;
        this.setName = name;
        this.cells = new ArrayList<Cell>();
    }
    
    public void addCell(Cell cell) {
        this.cells.add(cell);
    }
    
    public void paintColumn(Graphics2D g2, Color memberColor, Color neutral, Color antiMemberColor) {
        Iterator<Cell> cellIter = this.cells.iterator();
        while (cellIter.hasNext()) {
            cellIter.next().drawCellToCanvas(g2, memberColor, neutral, antiMemberColor);            
        }
    }
    
    public double getIndex() {
        return this.index;
    }
    
    public String getSetName() {
        return this.setName;
    }
    
    public ArrayList<String> getEntitiesForDimension(double ystart, double yend) {
        
        ArrayList<String> entities = new ArrayList<String>();
        
        Iterator<Cell> cellIter = this.cells.iterator();
        while (cellIter.hasNext()) {
            Cell cell = cellIter.next();
            if (cell.getCellIndex() >= ystart && cell.getCellIndex() <= yend) {
                entities.add(cell.getEntityName());
            }
            
        }
        
        return entities;
    }
    
}
