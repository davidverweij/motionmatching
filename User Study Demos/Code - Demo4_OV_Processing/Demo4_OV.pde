////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  //<>//
/////////////////////////////////////////////////* VARIABLES --> CHANGE WHERE NEEDED *//////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* --> */final static int SERVER_PORT_1_1 = 1755;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_1_2 = 1756;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_1 = 1788;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_2 = 1789;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int Watches = 2;
/* --> */final static int num_targets = 7;                               // amount of current targets
/* --> */boolean useServer = true;                                       // set to true if you are / want to be connected over WIFI
/* --> */boolean withWatch = useServer;                                       // false for target testing

///////////////////* OBJECTS AND THREADS */////////////////////////////////////////////////
ArrayList<Trial>    trialPackage     = null;    // Targets (class)
Server              server           = null;    // Server for laptop <--> phone connection (class, initiates Thread)                   
String              tagName = "ChannelThread";  // tag to search for in ADB messages (USB)


///////////////////* SCREEN & PROPERTIES */////////////////////////////////////////////////
float PPI = 89, PPCM = PPI/2.54, VDEGREE = .63*PPCM, CENTERX, CENTERY, TARGET_SIZE;                      // iMac 21.5": 102.46, Callisto: 220, Tablet: ?, Macbook Pro 15": 221         
int  winner_buffer_ini = 10;    // req. for buffer for gaps in selection (better UX, not better performance)
int[] winner_buffer = new int[num_targets];

long max_disconnect = 1000;          // maximum time for no ADB data before alert

boolean demoPaused = false; // system turned 'off'

final int WINDOWSIZE    =    292;          // a correlation window of 292 datapoints (at least 1.5 seconds)
//final int WINDOWSIZE    =    90;          // a correlation window of 292 datapoints (at least 1.5 seconds)

int FRAMERATE = 40;                      // for drawing

ArrayList<ArrayList<Long>>                  systemTime, androidTime;
ArrayList<ArrayList<ArrayList<Float>>>      targetXs, targetYs;
ArrayList<ArrayList<Long>>                  watchTimestamps;
ArrayList<ArrayList<Integer>>               watchSensorID, watchSensorFlipped, watchAccuracy;
ArrayList<ArrayList<Float>>                 watchYaw = null, watchRoll = null, watchPitch = null;

int LOW_SPEED = 90, MED_SPEED = 180, HIGH_SPEED = 270, VERY_HIGH_SPEED = 360;           //  deg./sec

// use a single global clock
long currentStudyTime, countDownStarted, trialStarted, finishedStudyTime, last_adb_time, waitCount, waitThres = 2000;
long old_currentST = 0;
List<Integer> selection = new ArrayList<Integer>(Watches);
List<Integer> winner = new ArrayList<Integer>(Watches);
List<Long> last_winner_time = new ArrayList<Long>(Watches);
boolean recording_data, flipped, finishedStudy, paused, trial_succes, instruction, wait;
int finishedFirstStudy = 0, STATE = 0, firstTrain = 0, tableSize= 0;
float yaw, pitch, roll;



///////////////////////////////////// TRAIN /////////////////

float border, trainRow, column0, column1, column2, column3, column4, columnTime, updateRow, headerSize, trainSize, subTrainSize, logoPosX, logoPosY, logoWidth, logoHeight;
float[] column = new float[5];
color WT = color(0, 161, 131), WTlight = color(207, 229, 225), WTborder = color(0, 135, 109);
PFont AllerBold, Aller, AllerDisplay;
Table trainTable;
PImage logo;

void setup()
{
  fullScreen(JAVA2D);
  //size(1280, 720, JAVA2D);        // for testing, make everything half the size
  //size(1920,1080);
  //size(640, 360);
  ellipseMode(CENTER);
  frameRate(FRAMERATE);

  CENTERX = width / 2;
  CENTERY = height / 2;

  Aller = createFont("assets/Aller_Rg.ttf", 50);
  AllerBold = createFont("assets/AllerBold.ttf", 50);
  AllerDisplay = createFont("assets/AllerDisplay.ttf", 150);
  textFont(Aller);

  trainTable = loadTable("trains.csv", "header");
  tableSize = trainTable.getRowCount()-1;
  logo = loadImage("assets/wavetraceOV.png");

  if (useServer) {
    server = new Server();
    server.start();
  }

  registerMethod("dispose", this); // register a close event to quit the adb thread. 

  applyScreenSize();

  initStudy();
}

void initStudy()
{
  currentStudyTime = System.currentTimeMillis();
  finishedStudyTime = 0;

  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;

  for (int i = 0; i < Watches; i++) {
    selection.add(-13);
    last_winner_time.add(System.currentTimeMillis());
  }

  finishedStudy = false;
  paused = false;

  countDownStarted = currentStudyTime;
  trialStarted = 0;

  recording_data = false;
  trial_succes = false;
  flipped = false;

  makeTrialPackage();      // compile all trials in one package;
  prepareTrial();          // add correlator and initialize and empty variables
}

void draw()
{
  checkConnection();
  drawTrainSchedule();
  runStudy();
  drawBorder();

  if (wait) {
    waitCount = System.currentTimeMillis();
    wait = false;
  }
}


void runStudy()
{
  currentStudyTime = System.currentTimeMillis();

  if (trialStarted != 0)     // We are in a trial screen
  {
    if (withWatch)
      if ((server.server_running.get(1) || server.server_running.get(3)) && currentStudyTime-waitCount>waitThres) {
        actUponWinner();
      }
    drawTargets();                      // UPDATE targets AND DRAW
  } else if (countDownStarted != 0)
  {
    countDownStarted = 0;
    trialStarted = System.currentTimeMillis();
    recording_data = true;  //start storing data
  }
}

void actUponWinner() {
  winner = new ArrayList<Integer>();                            // store in variable, possibly not to be intefered by ADBThread
  winner.addAll(selection);
  if (Collections.max(winner) >= 0) {
    for (int i = 0; i < winner.size(); i++) {
      if (System.currentTimeMillis()-last_winner_time.get(i)>2500 && winner.get(i)>=0) {      // prevent multiple selections wihtin each 1.5 seconds
        sendResult(i, winner.get(i));
        //sendBreak(i);
        last_winner_time.set(i, System.currentTimeMillis());
      }
    }
  }
}

void prepareTrial() {
  if (withWatch) {
    systemTime               = new ArrayList<ArrayList<Long>>(Watches);
    androidTime              = new ArrayList<ArrayList<Long>>(Watches);
    targetXs                 = new ArrayList<ArrayList<ArrayList<Float>>>(Watches);    // arraylist of arraylists
    targetYs                 = new ArrayList<ArrayList<ArrayList<Float>>>(Watches);
    watchTimestamps          = new ArrayList<ArrayList<Long>>(Watches);
    watchSensorID            = new ArrayList<ArrayList<Integer>>(Watches);
    watchSensorFlipped       = new ArrayList<ArrayList<Integer>>(Watches);
    watchAccuracy            = new ArrayList<ArrayList<Integer>>(Watches);
    watchYaw                 = new ArrayList<ArrayList<Float>>(Watches);
    watchRoll                = new ArrayList<ArrayList<Float>>(Watches);
    watchPitch               = new ArrayList<ArrayList<Float>>(Watches);

    for (int q = 0; q < Watches; q++) {
      systemTime.             add(new ArrayList<Long>());
      androidTime.            add(new ArrayList<Long>());
      targetXs.               add(new ArrayList<ArrayList<Float>>(num_targets));    // arraylist of arraylists
      targetYs.               add(new ArrayList<ArrayList<Float>>(num_targets));
      watchTimestamps.        add(new ArrayList<Long>());
      watchSensorID.          add(new ArrayList<Integer>());
      watchSensorFlipped.     add(new ArrayList<Integer>());
      watchAccuracy.          add(new ArrayList<Integer>());
      watchYaw.               add(new ArrayList<Float>());
      watchRoll.              add(new ArrayList<Float>());
      watchPitch.             add( new ArrayList<Float>());

      for (int i = 0; i < num_targets; i++) {                                     // initialize the second dimension of arraylists
        ArrayList<Float> target_x = new ArrayList<Float>(); 
        targetXs.get(q).add(target_x); 
        ArrayList<Float> target_y = new ArrayList<Float>();
        targetYs.get(q).add(target_y);
      }
    }
  }
}

void drawTargets() {
  // Update & draw the target position
  long now = System.currentTimeMillis();
  trialPackage.get(0).updatePos(now); 
  trialPackage.get(0).draw();
}

void restartCorrel() {
  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;

  recording_data = false;
  prepareTrial();
  recording_data = true;
}

void keyReleased() 
{
  if (key == ' ' && demoPaused) {
    demoPaused = false;
    initStudy();
  } else if (key == ' ' && !demoPaused) {
    demoPaused = true;
  } else if (key == 't') {
    dispose();
    exit();
  } else if (key == 'r') {
    trialStarted = 0;
    countDownStarted = currentStudyTime;
    prepareTrial();
  } else if (!withWatch) {
    if (key == CODED) {
      if (keyCode == RIGHT) {
      } else if (keyCode == LEFT) {
      } else if (keyCode == UP) {
      } else if (keyCode == DOWN) {
      }
    }
  }
} 


void stop()
{
  println("Closing sketch"); 
  if (withWatch) {
    for (int i = 0; i < Watches; i++) {
      if (server.server_running.get(i*2)) {
        server.sendMessage("stop_watch", i*2);
      }
    }
  }

  finishedStudy = true;
}

/*
 * Called on quit (via registerMethod) - clean up the thread
 */
public void dispose()
{
  if (useServer) {
    for (int i = 0; i < Watches; i++) {
      if (server.server_running.get(i*2)) {
        server.sendMessage("stop_watch", i*2);
      }
    }
  }
  if (server!=null) {
    try {
      server.quit();
      println("quit server");
    } 
    catch (Exception e) {
      println(e.getMessage());
    }
  }
}


void sendResult(int watch, int train) {
  if (withWatch) 
    if (server.server_running.get(watch*2)) 
      server.sendMessage("/wavetrace_show_button_"+(firstTrain+12+train), watch*2);    
}
void sendBreak(int watch) {
  if (withWatch) 
      if (server.server_running.get(watch*2)) 
        server.sendMessage("stop_sensordata", watch*2);
}

void checkConnection() {
  Boolean temp = true;
  if (withWatch) {
    for (int i = 0; i < Watches; i++) {
      if (server.server_running.get(1+(i*2))) {      // only the ADB servers
        temp = false;
        return;
      }
    }
  }
  demoPaused = temp;
}