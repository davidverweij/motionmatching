import processing.net.*;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.impl.client.DefaultHttpClient;
import java.awt.*;
import java.lang.Object.*;

class hueThread extends Thread {

  boolean running;           // Is the thread running?  Yes or no?
  int currentTransmit = 0;

  hueThread () {     // constructor
    running = false;
  }          

  void start() {
    try {
      println("Starting HUE Thread");
      httpClient = new DefaultHttpClient();
      running = true;  // Set running (the stop condition when false) to be  true
      super.start();   // hit go
    }
    catch (Exception E) {
      println("Die on hue Thread startup");
      quit();
    }
  }

  void run () {
    while (running) // stop condition is running==false
    {
      if (updateHUE) {
        /* for (int i = 0; i < HUES.length; i++) {
         sendHSBToHue(HUES[i][0], HUES[i][1], HUES[i][2], HUES[i][3]);
         }*/
        sendHue();

        updateHUE = false;
      }
      try {
        sleep(200L);          // maximum 10x a second sending signals to HUE
      } 
      catch (Exception E) {
        println("Die on HUE update. Quitting");
        quit();
      }
    }
  }

  void quit() 
  {
    println("Quitting hueThread...."); 
    running = false;  // Setting running to false ends the loop in run()
    interrupt();// In case the thread is waiting. . .
  }

  void sendHue() {
    currentTransmit++;
    if (currentTransmit>=HUES.length) currentTransmit = 0;
    String dataString = "{";
    dataString += "\"on\":" + ((HUES[currentTransmit][3]<10)?"false":"true");
    dataString += ", \"bri\":" + HUES[currentTransmit][3];
    dataString += ", \"sat\":" + HUES[currentTransmit][2];
    dataString += ", \"hue\":";
    dataString += HUES[currentTransmit][1]<<8;
    dataString += "}\r\n";

    String sendDataString = "http://" + HUE_IP + "/api/" + HUE_KEY +"/lights/" + (HUES[currentTransmit][0]) + "/state";  

    /*Client c = new Client(this, HUE_IP, 8000);
     c.write(sendDataString);
     c.stop();
     */
    try {
      StringEntity se = new StringEntity(dataString, "ISO-8859-1");     
      se.setContentType("application/json");
      HttpPut httpPut = new HttpPut(sendDataString);
      httpPut.setEntity(se);
      httpPut.addHeader("Accept", "application/json");                  // tell everyone we are talking JSON
      httpPut.addHeader("Content-Type", "application/json");
      HttpResponse response = httpClient.execute(httpPut);
      HttpEntity entity = response.getEntity();
      // needs to be done to ensure next put can be executed and connection is released
      if (entity != null) entity.consumeContent();
    } 
    catch (IOException e) {
      e.printStackTrace();
    }


    println("sent to hue:" + dataString);
  }
}