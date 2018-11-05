/*
 * Thread imports
 */
import java.io.InputStream.*; 
import java.io.InputStreamReader;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.lang.System.*;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;

import static java.lang.Thread.sleep;


/* 
 * Thread class
 */
public class adbThread implements Runnable 
{
  int wait;                  // How many milliseconds should we wait in between executions?
  int server_num;             // server ID
  String id;                 // Thread name
  int count;                 // counter
  color black, green;        // confirmation color

  String tag;                // the tag we are searching for in the adb stream... 
  boolean package_started = false;

  BufferedReader br;         // reader to get the adb data.
  Process read;              // the external adb process
  Correlator correl      = null;

  // packet counter/speed vars
  long startTime; 
  long time;
  int packetsCounted;
  float adbpacketRate; 
  float FrameRate;

  int sensorName;
  int latestTime;
  int latency;
  int accuracy;
  long timestamp, android_time, watch_time, elapsed_realtime, compensation, reference_laptop_time, reference_watch_time, reference_android_time;

  protected Socket adbClientSocket = null;
  protected ServerSocket adbServerSocket = null;
  InputStreamReader inputStreamReader;
  BufferedReader bufferedReader;
  int error_counter = 0;
  long socket_check_timer = 1000;   // send poll message each ... times. If after ... times not receveived back. Connection presumed lost. 
  long socket_timeout = 0;          // counter for socket timeout;
  boolean poll = false;             // boolean if poll is send

  /* Constructor, create the thread. It is *not* running by default   */
  adbThread (int waitTime, String threadName, int _server_num, String tagName, ServerSocket _serverSocket) 
  {
    wait = waitTime;
    server_num = _server_num;
    id = threadName;
    tag = tagName; 
    adbServerSocket = _serverSocket;
    package_started = false;
    correl = new Correlator(num_targets, WINDOWSIZE, 0.8);
    //setupADB();
  }

  /** Get the current packet rate  */
  float getADBPacketRate() 
  {
    return adbpacketRate;
  }

  float getFrameRate() 
  {
    return FrameRate;
  }

  /* Inits the thread.  */
  void setupADB() 
  {
    println("ADB " + server_num + " : start");
    try {
      //println("startADB: waiting for connection");
      adbClientSocket = adbServerSocket.accept();
      inputStreamReader = new InputStreamReader(adbClientSocket.getInputStream());
      bufferedReader = new BufferedReader(inputStreamReader);
      socket_timeout = System.currentTimeMillis();
      println("ADB " + server_num + " = CONNECTED");
      initStudy();
      demoPaused = false;
      demoStarted = true;
      recording_data=true;

      //println("Starting to read adbData (updates every "+ wait + " milliseconds) and threshold "); 
      server.server_running.set(server_num, true); // Set running (the stop condition when false) to be  true
    } 
    catch (IOException ex) {
      println("ADB " + server_num + " : Problem in establishing connection");
      //println(ex.toString());
    }
  }

  /* Runs the thread - triggered when we call start   */
  void run () 
  {
    String line; // where we store the data from the adb bus

    // init data about the timing
    startTime = System.currentTimeMillis(); 
    packetsCounted = 0;
    adbpacketRate = 0; 
    setupADB();

    while (server.server_running.get(server_num)) // stop condition is running==false
    {

      if (package_started) {
        if (time - last_adb_time > max_disconnect) {
          demoPaused = true;
          server.server_running.set(server_num, false);
          println("ADB " + server_num + " : no data for 1 second");
        }
      }
      try 
      {  
        if (bufferedReader!=null && bufferedReader.ready() && (line = bufferedReader.readLine()) != null) // check for and read data
        {  
          time = System.currentTimeMillis();
          package_started = true;
          last_adb_time = time;
          //println(line);

          // find the "###" packet starter mark
          int hashPos = line.indexOf("###");            
          if (hashPos!=-1)
          {
            last_adb_time = time;
            line = line.substring(hashPos+3);
            //println(line);
            String[] terms = split(line, ";");

            /*    ANY SPECIFIC INSTRUCTION MESSAGE FROM THE SMARTWACH MUST CONTAIN 2 ELEMENTS    */

            if (terms.length==2)
            {
              if (terms[1].equals("/FLIPPED") == true) {        // the coordinate system has been remapped. We have to adjust all 'old' YAW values in the windowsize with 180 degrees.
                println("ADB " + server_num + " FLIPPED COORDINATE SYSTEM!!");
                if (recording_data) {
                  correl.flipWatchData(watchYaw.get(floor(server_num/2)), watchPitch.get(floor(server_num/2)));
                  flipped = !flipped;
                }
              }
            }

            /*    ANY LATENCY TEST MUST CONTAIN 6 ELEMENTS    */

            if (terms.length==5) 
            {                              
              if (terms[0].equals("LATENCY") == true) {    // start counting.
                // LATENCY_AVERAGE; average latency; android time; android time at measurement; smartwatch time at measurement; latency single way at measurement

                android_time =               Long.parseLong(terms[1]);
                reference_android_time =     Long.parseLong(terms[2]);
                reference_watch_time =       Long.parseLong(terms[3]);
                latency =                          parseInt(terms[4]);

                //println("Latency message, with: " + latency + "milliseconds");
                reference_laptop_time = time - (android_time - reference_android_time) - (latency/2);
              }
            } else if (terms.length>=6)        

              /*    REGULAT SENSOR READINGS ARE 7 ELEMENTS OR MORE    */

            {   

              try 
              {      
                android_time =      Long.parseLong(terms[0]);
                timestamp =         Long.parseLong(terms[1]);
                sensorName =              parseInt(terms[2]);
                accuracy =                parseInt(terms[3]); 
                yaw =             Float.parseFloat(terms[4]);
                roll =            Float.parseFloat(terms[5]);
                pitch =           Float.parseFloat(terms[6]);

                //println(yaw);

                if (recording_data)
                {              
                  watchYaw.get(floor(server_num/2)).add(yaw);
                  watchPitch.get(floor(server_num/2)).add(pitch);

                  long laptopTimestamp = reference_laptop_time+(timestamp-reference_watch_time);
                  for (int d = 0; d < num_targets; d++) {                      
                    targetXs.get(floor(server_num/2)).get(d).add(trialPackage.get(STATE).targets.get(d).getTargetPos(laptopTimestamp)[0]);
                    targetYs.get(floor(server_num/2)).get(d).add(trialPackage.get(STATE).targets.get(d).getTargetPos(laptopTimestamp)[1]);
                  }
                  
                  int result = correl.execute(watchYaw.get(floor(server_num/2)), watchPitch.get(floor(server_num/2)), targetXs.get(floor(server_num/2)), targetYs.get(floor(server_num/2)));
                  selection.set(floor(server_num/2),result);

                  if (result != -9 && !recording_data) {
                    for (int d = 0; d < num_targets; d++) {                      
                      targetXs.get(floor(server_num/2)).get(d).remove(0);
                      targetYs.get(floor(server_num/2)).get(d).remove(0);
                    }
                    watchYaw.get(floor(server_num/2)).remove(0);
                    watchPitch.get(floor(server_num/2)).remove(0);
                  }
                  //println(selection);
                }
              }         
              catch (NumberFormatException e) 
              {
                println("ADB " + server_num + " : Number format exception - getting watch movement from: " + line);
              }
            }
          }

          // calculate the update rate.
          long now = System.currentTimeMillis();
          if (now>startTime+250) // calc is every 250 ms. Means a bit inaccurate....
          {
            adbpacketRate = (float)packetsCounted*4.0;
            FrameRate = frameRate;
            startTime = now;
            packetsCounted=0;
          }   
          packetsCounted++;
        }
      }
      catch (IOException E) {
        println("Exit in read"); 
        server.server_running.set(server_num, false);
        package_started = false;
      }
    }

    println("Quitting ADB " + server_num + " ...."); 
    //server.sendMessage("stop_sensordata");      // if adb breaks, make sure phone stops sending
    try {
      adbClientSocket.close();
      bufferedReader.close();
    }
    catch (Exception e) {
      println("Die on file close!");
    } // close the reader
    //println("Quit finished");
    
  }
}

public class Correlator
{
  PearsonsCorrelation pCorrelation; // the correlation math object

  int numTargets;         // how many targets we are dealing with
  int windowSize;         // how many samples in a correlation window
  double correlThreshold; // correlation threshold to trigger selection

  long duration;          // how long the correlation calc takes....

  // incoming data to correlate
  double[] xWatchArray;
  double[] yWatchArray;

  double[][] xTargetArray;
  double[][] yTargetArray;

  double[][] corResults;  // the results of the coorelation - so we can check raw data....

  // constructor and give default sizes/thresholds
  public Correlator(int _numTargets, int _windowSize, double _correlThreshold)
  {
    pCorrelation = new PearsonsCorrelation();
    numTargets      = _numTargets;
    windowSize      = _windowSize;
    correlThreshold = _correlThreshold;

    println("Ready to correlate " + numTargets + " targets for each " + windowSize + " datapoints and " + (double)correlThreshold + " as threshold");
  }

  public int execute( ArrayList<Float> _watchX, ArrayList<Float> _watchY, ArrayList<ArrayList<Float>> _targetsXs, ArrayList<ArrayList<Float>> _targetsYs) {
    if (_watchX.size()<windowSize || _targetsXs.get(0).size()<windowSize)       //make sure the windowsize is big enough
      return -9;                         // not enough datapoints

    xTargetArray = new double[numTargets][];
    yTargetArray = new double[numTargets][];
    corResults = new double[2][numTargets];

    // take a sublist of the last WINDOWSIZE datapoints and transfer to an array (also preserving the references)
    xWatchArray = floatToDouble(_watchX);
    yWatchArray = floatToDouble(_watchY);

    for (int w = 0; w < numTargets; w++) {
      xTargetArray[w] = floatToDouble(_targetsXs.get(w));
      yTargetArray[w] = floatToDouble(_targetsYs.get(w));
    }  

    for (int i=0; i<numTargets; i++)
    {  // run and store the correlation 
      corResults[0][i] = pCorrelation.correlation(xWatchArray, xTargetArray[i]);
      corResults[1][i] = pCorrelation.correlation(yWatchArray, yTargetArray[i]);
    }

    return checkCorrelations(corResults);
  }

  private double[] floatToDouble(ArrayList<Float> input) {
    int arr_start = input.size()-windowSize;
    double[] converted = new double[windowSize];
    for (int l = 0; l < windowSize; l++) {   
      converted[l] = input.get(arr_start + l);
    }
    return converted;
  }


  private int checkCorrelations(double[][] results) {
    ArrayList succes = new ArrayList<Integer>();
    int arr_length = min(results[0].length, results[1].length);
    for (int l = 0; l < arr_length; l++) {
      if (results[0][l] > correlThreshold && results[1][l] < -correlThreshold) {
        // CORRELATION!
        succes.add(l);
      }
    }
    if (succes.size()>0)  // we have correlation
    {
      if (succes.size()>1) { // multiple correlation
        return checkBest(succes, results);
      }

      // else return the winner!
      return (int)succes.get(0);
    }
    return -1; // no correlation
  }

  private int checkBest(ArrayList winners, double[][] raw_winners) {
    int limit = winners.size();
    double x_max = Double.MIN_VALUE;
    double y_max = Double.MIN_VALUE;
    double x_y_max = Double.MIN_VALUE;
    int x_maxPos = -1;
    int y_maxPos = -1;
    int x_y_maxPos = -1;

    for (int i = 0; i < limit; i++) {
      int pos = (int)winners.get(i);
      double x_val = raw_winners[0][pos];
      double y_val = -1*raw_winners[1][pos];      // computer has flipped coordinate system
      double x_y_val = x_val + y_val;

      if (x_val > x_max) {
        x_max = x_val; 
        x_maxPos = pos;
      }
      if (y_val > y_max) {
        y_max = y_val; 
        y_maxPos = pos;
      }
      if (x_y_val > x_y_max) {
        x_y_max = x_y_val; 
        x_y_maxPos = pos;
      }
    }
    if (x_maxPos == y_maxPos) return x_maxPos;      // one target correlates highest in both axis
    return x_y_maxPos;                              // assuming no correlation is the same, choose combined highest
  }

  public void flipWatchData(ArrayList<Float> _watchX, ArrayList<Float> _watchY) {
    int x_size = _watchX.size();
    int y_size = _watchY.size();
    int x_pos = x_size-windowSize;
    int y_pos = y_size-windowSize;
    if (x_pos < 0) x_pos = 0;
    if (y_pos < 0) y_pos = 0;

    for (int i = x_pos; i < x_size; i++) {
      _watchX.set(i, normalizeAngle((_watchX.get(i) + PI)));
    }

    for (int i = y_pos; i < y_size; i++) {
      _watchY.set(i, normalizeAngle((_watchY.get(i) + PI)));
    }
  }

  public float normalizeAngle(float angle)
  {
    float newAngle = angle;
    while (newAngle <= -PI) newAngle += 2*PI;
    while (newAngle > PI) newAngle -= 2*PI;
    return newAngle;
  }
}