import java.util.Collections;

public class WATCHcom implements Runnable 
{
  UDP udp_watch;  // define the UDP object
  int watch_port        = 6628;    // the destination port
  long correlation_window = 2000; // milliseconds
  double cor_thres = 0.86;
  int roll_time_thres = 200;    // looking at the last ... milliseconds for roll_changes. Roll Range ~ -150 <--> 150 (exaggerated max)
  long extra_STATE_thres = 2000;     // add time when there is a state change, to prevent correlations when a new state is opened
  long last_light1 = 0;         // to adjust scale of light 1 actions
  long newSTATE = -9;
  int minimum_datapoints =  50; //  50 = minimum of ~30HZ on average
  int currentSTATE = -1;
  boolean receiving = false;        // to indicate if there is a datastream from the watch
  long received_thres = 2000;  // if longer then ... millisecond no message, probably watch disconnected
  long last_received = 0;  // if longer then ... millisecond no message, probably watch disconnected
  long last_lamp = 0;

  int yaw, pitch, roll;
  ArrayList<ArrayList<ArrayList<Float>>>      targetXs, targetYs;          //multiple lights, multiple targets, multiple positions
  ArrayList<Integer>      watchYaw = null, watchRoll = null, watchPitch = null;
  int[] Yawrange = {0, 0, 0}, Pitchrange = {0, 0, 0};
  ArrayList<Long>        sensorTime;
  Correlator correl      = null;

  /* Constructor, create the thread. It is *not* running by default   */
  WATCHcom () 
  {
    udp_watch = new UDP(this, watch_port);
    udp_watch.setReceiveHandler("WATCHreceiver");
    udp_watch.listen(true);

    initArrays();        // in a function, so we can call it at a STATE switch // is called by default due to 'STATE CHANGE'

    correl = new Correlator(cor_thres);      // indicate correlation threshold
  }

  void initArrays() {                                      // initialize (and thus wipe) arraylist on request
    watchYaw = new ArrayList<Integer>();
    watchRoll = new ArrayList<Integer>();
    watchPitch= new ArrayList<Integer>();
    sensorTime = new ArrayList<Long>();


    targetXs = new ArrayList<ArrayList<ArrayList<Float>>>();    // arraylist of arraylists
    targetYs = new ArrayList<ArrayList<ArrayList<Float>>>();    //multiple lights, multiple targets, multiple positions (3x)

    for (int i = 0; i < Lights.size(); i++) {                     // prepare for all lights, even though might not need it
      targetXs.add(new ArrayList<ArrayList<Float>>());
      targetYs.add(new ArrayList<ArrayList<Float>>());
    }

    if (STATE == 0) {
      for (int i = 0; i < Lights.size(); i++) {         //for each light an arraylist
        if (lamps[i].on())                              // if used in demo
          for (int q = 0; q < Lights.get(i).get(0).targets.size(); q++) {
            targetXs.get(i).add(new ArrayList<Float>()); 
            targetYs.get(i).add(new ArrayList<Float>());
          }
      }
    } else {        // interacting with one specific light, thus only need to initiate one light
      for (int i = 0; i < Lights.size(); i++) {         
        if (i == STATE-1)          // only for the selected STATE / Light - create one! list
          for (int q = 0; q < Lights.get(i).get(1).targets.size(); q++) {      // second menu always
            targetXs.get(i).add(new ArrayList<Float>()); 
            targetYs.get(i).add(new ArrayList<Float>());
          }
      }
    }
  }

  /* Runs the thread - triggered when we call start   */
  void run () 
  {
    while (udpWATCH_running) {
      if (simulation) responds();
      // check if state change!
      if (lampToggle) {
        recording_data = false;
        lampToggle = false;
        println("lamp Toggle!");
        initArrays();
        newSTATE = millis();
      }
      if (currentSTATE!=STATE) {
        initArrays();        // in a function, so we can call it at a STATE switch
        currentSTATE = STATE;
        newSTATE = millis();
      } else if (newSTATE>0 && millis()-newSTATE>extra_STATE_thres) {
        recording_data = true;    // safety off
        newSTATE = -9;
      }

      //if (receiving == true && millis(
      delay(1);
    }
    udp_watch.close(); 
    println("Watch Thread Quit");
  }


  void WATCHreceiver(byte[] data, String ip, int port ) {  // <-- extended handler
    /*
     *    This function is called whenever a UDP message is received. It does the following: Stores the incoming data. Computes a correlation if enough (recent) data is collected (min: 30Hz)
     *    It also checks whether someone is adjusting the brightness (roll), which can only happen when there is not that much yaw and pitch movement (to prevent accidental changes).
     *    It also checks whether a big movement is done away from the 'lamp' (downwards). To 'deselect' that lamp and effectively go back.
     */
    long now = millis();                       // NOTE: millis() exceeds its limits (and goes back to 0) after roughly 50 days. Bare in mind in 'deploying' this demo. 
    String message = new String(data);         // 
    incomingWatch = true;
    last_incomingWatch = now;
    String[] terms = split(message, ";"); 
    if (terms.length == 3) {    // we collected enough data from this package
      try {
        yaw = Integer.valueOf(terms[0]); 
        roll = Integer.valueOf(terms[1]); 
        pitch = Integer.valueOf(terms[2]);      

        receiving = true;


        if (recording_data) {
          watchYaw.add(yaw); 
          watchRoll.add(roll); 
          watchPitch.add(pitch); 
          sensorTime.add(now); 

          if (sensorTime.size()>1)      // so don't check the array at first (or last) reading
            while (sensorTime.get(sensorTime.size()-1)-sensorTime.get(0)>correlation_window) {     
              sensorTime.remove(0); // remove the oldest value untill we have values from now back to <threshold time> ago
              watchYaw.remove(0); 
              watchRoll.remove(0); 
              watchPitch.remove(0);
              for (int i = 0; i < targetXs.size(); i++)              // check all lights      // targetXs should equal targetYs...
                if (lamps[i].on())                              // if used in demo
                  for (int q = 0; q < targetXs.get(i).size(); q++)      // check all targets 
                    if (targetXs.get(i).get(q).size()!= 0) {            // additional (overkill) safety
                      targetXs.get(i).get(q).remove(0);
                      targetYs.get(i).get(q).remove(0);
                    }
            }

          if (STATE == 0) {   // all are idle
            for (int i = 0; i < Lights.size(); i++)                            // Lights
              if (lamps[i].on())                              // if used in demo
                for (int q = 0; q < Lights.get(i).get(0).targets.size(); q++) {     // Targets, STATE 0 should only be one per light
                  targetXs.get(i).get(q).add((float)Lights.get(i).get(0).targets.get(q).getTargetPos(now)[1]); // x-float values
                  targetYs.get(i).get(q).add((float)Lights.get(i).get(0).targets.get(q).getTargetPos(now)[2]); // y-float values
                }
          } else {
            for (int i = 0; i < Lights.size(); i++)                            // Lights
              if (i == STATE-1)                        // only for the selected STATE / Light - fill (one!) list
                for (int q = 0; q < Lights.get(i).get(1).targets.size(); q++) {     // Targets, STATE 1 should only be one per light
                  targetXs.get(i).get(q).add((float)Lights.get(i).get(1).targets.get(q).getTargetPos(now)[1]); // x-float values      //get(0) as there should only be one list!
                  targetYs.get(i).get(q).add((float)Lights.get(i).get(1).targets.get(q).getTargetPos(now)[2]); // y-float values
                }


            //CHECK 'CANCEL' MOVEMENT HERE
          }


          // CORRELATE HERE!
          responds();
        }
      } 
      catch (NumberFormatException e)       // if cannot parse, don;t do anything mentioned above
      {
        println("Error in parsing from UDP data to INTs");
      }
    }
  }

  void responds() {
    int result = -9;
    float roll_brightness = 0;
    float yaw_average = 0;
    float pitch_average = 0;  
    if (sensorTime.size()>minimum_datapoints || simulation) {               // we want a minimum of datapoints (see settings above)     
      try {

        if (!simulation) {
          result = correl.execute(currentSTATE, watchYaw, watchPitch, targetXs, targetYs);
          if (STATE != 0) {
            roll_brightness = correl.getRoll(watchRoll, sensorTime);
            yaw_average = correl.getRoll(watchYaw, sensorTime);
            pitch_average = correl.getRoll(watchPitch, sensorTime);
            //println("roll = " + roll_brightness);
            //println("yaw = " + yaw_average);
          }
        } else {
          result = numberKEYBOARD;
          numberKEYBOARD = -9;
        }

        // ACT ON RESULT HERE ! (but we want to know the state to do so
        if (result>=0) {        // -9 is no result, -1 is no selection. Others are selections (starting at 0)
          println("Winner is: " + result);
          switch(STATE) {
          case 0:
            recording_data = false;    // effectively select light
            if (result != 9) {
              STATE = result+1;
              last_lamp = millis();
            }
            // Yawrange = correl.getYawRange(watchYaw);      // yawrange is a bit buggy
            Pitchrange = correl.getYawRange(watchPitch);
            break;
          case 1:
            if (millis()-last_light1>100) {
              last_light1 = millis();
              switch(result) {        // [0] = width of beam walllight,
              case 0:
                lightPARAM[0] = constrain(lightPARAM[0]-1, 0, LEDstrips[0].length-2);    // 2 - 100%      // 2%, as off is done via brightness
                break;
              case 1:
                lightPARAM[0] = constrain(lightPARAM[0]+1, 0, LEDstrips[0].length-2);    // 2 - 100%
                break;
              case 9:
                if (simulation) {
                  recording_data = false;    // effectively de-select light
                  STATE = 0;
                  println("deselection");
                }
                break;
              default:
                println("hmmm, is there a new target in light 1 I am not aware of?");
              }
            }
            break;
          case 2:                    // [1] standmode : 0 = all lights on, 1 = top lights on, 2 = bottom lights on; 
            if (result == 9) {            
              if (simulation) {
                recording_data = false;    // effectively de-select light
                STATE = 0;
                println("deselection");
              }
              break;
            } else lightPARAM[1] = result;
            break;
          case 3:                    // [2] 0 = cold white --> 100 = warm white
            switch(result) {        
            case 0:
              lightPARAM[2] = constrain(lightPARAM[2]+1, -75, 75);    // -50 / 50
              break;
            case 1:
              lightPARAM[2] = constrain(lightPARAM[2]-1, -75, 75);    // -50 / 50
              break;
            case 9:
              if (simulation) {
                recording_data = false;    // effectively de-select light
                STATE = 0;
                println("deselection");
              }
              break;
            default:
              println("hmmm, is there a new target in light 1 I am not aware of?");
            }
            break;
          default:
            println("error! should not be possible in result / watchCOM");
            break;
          }
        }
        // ACT ON BRIGHTNESS & DESELCTION  HERE
        if (STATE != 0 && recording_data) {
          //println(roll_brightness);
          if (roll_brightness < -40)
            brightness[STATE-1] = constrain(brightness[STATE-1]-1.0, 50, 255);
          else if (roll_brightness > 40)
            brightness[STATE-1] = constrain(brightness[STATE-1]+1.0, 50, 255);


          if (pitch_average < -100 /* more reliable demo */
          /*Yawrange[2] != 0 &&  (yaw_average < Yawrange[0]-(Yawrange[2]) || yaw_average > Yawrange[1]+(Yawrange[2]))        // yaw seems to work more buggy than pitch
           ||  */
            /*(Pitchrange[2] != 0 &&  (pitch_average < Pitchrange[0]-(Pitchrange[2]) || pitch_average > Pitchrange[1]+(Pitchrange[2])))
            || millis()-last_lamp>7000*/) {                // if you go beyond the yaw range used to make selection, exit lamp
            //println("yaw average = " + yaw_average + " range[0] = " + Yawrange[0] + " range[1] " + Yawrange[1] + " diff = " + Yawrange[2]);
            //println("pitch average = " + pitch_average + " range[0] = " + Pitchrange[0] + " range[1] " + Pitchrange[1] + " diff = " + Pitchrange[2]);
            recording_data = false;    // effectively de-select light
            STATE = 0;
            println("deselection");
          }
        }
      } 
      catch (Exception e) {
        println("Error in Correlator!");
        recording_data = false;
      }
    }
  }


  public class Correlator
  {
    PearsonsCorrelation pCorrelation; // the correlation math object

    int numTargets;         // how many targets we are dealing with
    double correlThreshold; // correlation threshold to trigger selection

    // incoming data to correlate
    double[] xWatchArray;
    double[] yWatchArray;

    double[][][] xTargetArray;
    double[][][] yTargetArray;

    double[][] corResults;  // the results of the coorelation - so we can check raw data....

    // constructor and give default sizes/thresholds
    public Correlator(double _correlThreshold)
    {
      pCorrelation = new PearsonsCorrelation();
      correlThreshold = _correlThreshold;

      println("Ready to correlate with " + (double)correlThreshold + " as threshold");
    }

    public int execute(int _STATE, ArrayList<Integer> _watchX, ArrayList<Integer> _watchY, ArrayList<ArrayList<ArrayList<Float>>> _targetsXs, ArrayList<ArrayList<ArrayList<Float>>> _targetsYs) {     

      int STATE = _STATE;

      xTargetArray = new double[_targetsXs.size()][][];      // copy all incoming data
      yTargetArray = new double[_targetsYs.size()][][];
      for (int i = 0; i < xTargetArray.length; i++) {
        if (lamps[i].on())                              // if used in demo
          if (_targetsXs.get(i).size()>0) {
            xTargetArray[i] = new double[_targetsXs.get(i).size()][];
            yTargetArray[i] = new double[_targetsYs.get(i).size()][];
            for (int q = 0; q < xTargetArray[i].length; q++) {
              xTargetArray[i][q] = FloattoDouble(_targetsXs.get(i).get(q));
              yTargetArray[i][q] = FloattoDouble(_targetsYs.get(i).get(q));
            }
          }
      }  

      if (STATE == 0)  corResults = new double[2][_targetsXs.size()];                // minimize. As one light has only one target in idle, we can join them in this correl
      else             corResults = new double[2][_targetsXs.get(STATE-1).size()];   // if above, then 0 = light 1, 1 = light 2 etc. Otherwise, 0 = target 1, 1 = target 2 et


      xWatchArray = InttoDouble(_watchX);
      yWatchArray = InttoDouble(_watchY);
      if (STATE == 0) {
        for (int i=0; i<xTargetArray.length; i++)
          if (lamps[i].on())                              // if used in demo
          {  // run and store the correlation 
            corResults[0][i] = pCorrelation.correlation(xWatchArray, xTargetArray[i][0]);
            corResults[1][i] = pCorrelation.correlation(yWatchArray, yTargetArray[i][0]);
          } else {
            corResults[0][i] = 0.0d;    // if not in use, make result 0.
            corResults[0][i] = 0.0d;
          }
      } else {
        for (int i=0; i<xTargetArray[STATE-1].length; i++)
        {  // run and store the correlation 
          corResults[0][i] = pCorrelation.correlation(xWatchArray, xTargetArray[STATE-1][i]);
          corResults[1][i] = pCorrelation.correlation(yWatchArray, yTargetArray[STATE-1][i]);
        }
      }

      return checkCorrelations(corResults, STATE);
    }

    public float getRoll(ArrayList<Integer> _watchR, ArrayList<Long> _sensorTime) {
      long latest = _sensorTime.get(_sensorTime.size()-1);
      int index = Collections.binarySearch(_sensorTime, latest-roll_time_thres);
      if (index<0) index = -(index+1);

      long sublist_watchR = 0;
      for (int i = index; i < _watchR.size(); i++)
        sublist_watchR+=_watchR.get(i);

      return (float)sublist_watchR/(_watchR.size()-index);
    }

    public int[] getYawRange(ArrayList<Integer> _watchY) {
      int[] range = {0, 0, 0};        // {left range, right range, difference}
      range[0] = Collections.min(_watchY);
      range[1] = Collections.max(_watchY);
      range[2] = range[1]-range[0];

      return range;
    }

    private double[] InttoDouble(ArrayList<Integer> input) {
      int size = input.size(); 
      double[] converted = new double[size];
      for (int i = 0; i < size; i++) {   
        converted[i] = input.get(i);
      }
      return converted;
    }

    private double[] FloattoDouble(ArrayList<Float> input) {
      int size = input.size(); 
      double[] converted = new double[size];
      for (int i = 0; i < size; i++) {   
        converted[i] = input.get(i);
      }
      return converted;
    }


    private int checkCorrelations(double[][] results, int _STATE) {
      ArrayList succes = new ArrayList<Integer>();
      int arr_length = min(results[0].length, results[1].length);
      for (int l = 0; l < arr_length; l++) {
        if (_STATE == 2 || (STATE == 0 && l == 1)) {                     // for the square lights (STATE 2 / STATE 0 Target 1), x correlation can be mirrored (depending on position)
          if (abs((float)results[0][l]) > correlThreshold && results[1][l] < -correlThreshold) {
            // CORRELATION!
            succes.add(l);
          }
        } else {      // other lamps cannot be mirrored
          if (results[0][l] > correlThreshold && results[1][l] < -correlThreshold) {
            // CORRELATION!
            succes.add(l);
          }
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

    //public void flipWatchData(ArrayList<Float> _watchX, ArrayList<Float> _watchY) {
    //  int x_size = _watchX.size();
    //  int y_size = _watchY.size();
    //  int x_pos = x_size-windowSize;
    //  int y_pos = y_size-windowSize;
    //  if (x_pos < 0) x_pos = 0;
    //  if (y_pos < 0) y_pos = 0;

    //  for (int i = x_pos; i < x_size; i++) {
    //    _watchX.set(i, normalizeAngle((_watchX.get(i) + PI)));
    //  }

    //  for (int i = y_pos; i < y_size; i++) {
    //    _watchY.set(i, normalizeAngle((_watchY.get(i) + PI)));
    //  }
    //}

    public float normalizeAngle(float angle)
    {
      float newAngle = angle;
      while (newAngle <= -PI) newAngle += 2*PI;
      while (newAngle > PI) newAngle -= 2*PI;
      return newAngle;
    }
  }
}