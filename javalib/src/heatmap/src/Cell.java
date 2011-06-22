import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.geom.Rectangle2D;


public class Cell {
    
    private Rectangle2D.Double rect;
    private Set set;
    private Entity entity;
    // -1 to 1
    private double membershipValue = -2;
    
    // lazy instantiation
    private double getMembershipValue() {
        if (this.membershipValue < -1) {
            this.membershipValue = set.membershipValue(this.entity);
        }
        return this.membershipValue;
    }
    
    public Cell(double xstart, double ystart, double width, double height, Set set, Entity entity) {
        this.set = set;
        this.entity = entity;
        setCoordinates(xstart, ystart, width, height);
    }
    
    public String getEntityName() {
        return this.entity.getValue();
    }
    
    public double getCellIndex() {
        return rect.getMinY();
    }
    
    // rectangle of 
    public void setCoordinates(double xstart, double ystart, double width, double height) {
        this.rect = new Rectangle2D.Double(xstart, ystart, width, height);
    }

    public static Color shade(Color color, double fraction) {
        int red   = (int) Math.round (color.getRed() * fraction);
        int green = (int) Math.round (color.getGreen() * fraction);
        int blue  = (int) Math.round (color.getBlue()  * fraction);

        if (red   < 0) red   = 0; else if (red   > 255) red   = 255;
        if (green < 0) green = 0; else if (green > 255) green = 255;
        if (blue  < 0) blue  = 0; else if (blue  > 255) blue  = 255;    

        int alpha = color.getAlpha();

        return new Color (red, green, blue, alpha);
    }
    
    public void drawCellToCanvas(Graphics2D g2, Color memberColor, Color neutral, Color antiMemberColor) {
        
        // fade to the level of membership value
        Color cellColor;
        if (getMembershipValue() > 0) {
            cellColor = memberColor;
        } else if (getMembershipValue() == 0) {
            cellColor = neutral;
        } else {
            cellColor = antiMemberColor;
        }
        
        cellColor = shade(cellColor, Math.abs(getMembershipValue()));
        
        g2.setColor(cellColor);   
        g2.fill(rect);
        //g2.setColor(Color.GRAY);
        g2.draw(this.rect);
    }

}
