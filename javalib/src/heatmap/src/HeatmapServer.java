import java.io.*;
import java.net.*;
import java.util.*;

public class HeatmapServer extends Thread {

	public Socket client = null;

	public HeatmapServer(Socket client) {
		this.client = client;
	}

	public void run() {

		BufferedReader in = null;
		DataOutputStream out = null;
		try {

			in = new BufferedReader(new InputStreamReader(client.getInputStream()));

			String base64gif = SetEntityGrid.getBase64Gif(in);

			out = new DataOutputStream(client.getOutputStream());
			out.writeUTF(base64gif);
			out.flush();

			// cleanup
			out.close();
			in.close();

		} catch (IOException e) {
			System.out.println("Service Failed!");
			try {
				if (in != null) {
				in.close();
				}
				if (out != null) {
				out.close();
				}
			} catch (Exception ex) {
				//	
				ex.printStackTrace();
			}
		} catch (Exception e) {
			System.out.println("Failed to generate image!");
			try {
				if (in != null) {
				in.close();
				}
				if (out != null) {
				out.close();
				}
			} catch (Exception ex) {
				ex.printStackTrace();
				//	
			}
		}
	}

	public static void main (String args[]) throws Exception {

		ServerSocket Server = new ServerSocket(7777, 10, InetAddress.getByName("127.0.0.1"));
		System.out.println("Listening on port 7777");

		// accept connections
		while (true) {
			Socket conn = Server.accept();
			(new HeatmapServer(conn)).start();
		}
	

	}

}

