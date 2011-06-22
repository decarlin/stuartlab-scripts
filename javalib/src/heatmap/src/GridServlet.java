

import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.InputStream;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.*;


public class GridServlet extends javax.servlet.http.HttpServlet {

    public GridServlet() {
        // TODO Auto-generated constructor stub
    }
    
    public void doGet(HttpServletRequest request, HttpServletResponse response) {
        doPost(request, response);
    }
    
    public void doPost(HttpServletRequest request, HttpServletResponse response) {
        
        /*
        if (request.getContentType().compareTo("application/json") != 0) {
            return;
        }
        */

        DataInputStream in = null;
        try {
            in = new DataInputStream((InputStream)request.getInputStream());
            String text = in.readUTF();
            
            String message = "Test BEAST!";
            response.setContentType("text/plain");
            response.setContentLength(message.length());
            PrintWriter out = response.getWriter();
            out.println(message);
            in.close();
            out.close();
            out.flush();
            
        } catch (Exception e) {
             //
        }
        
    }

}
