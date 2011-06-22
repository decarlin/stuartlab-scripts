import org.json.JSONObject;

public class JSONClassifier {
    
    private final static int types[] = { 1, 2, 3 };
    
    public int classify(JSONObject jsonObj) {
        
        // sets classification
        try {
            JSONObject metas = jsonObj.getJSONObject("_metadata");
            String type = metas.getString("type");
            // sets are the columns
            if (type.compareTo("set") == 0) {
                return types[0];
            } else if (type.compareTo("info") == 0) {
                return types[1];
            } else if (type.compareTo("rows") == 0) {
                return types[2];
            }
        } catch (Exception e) {
            //
        }
        

        return types[1];
    }

}
