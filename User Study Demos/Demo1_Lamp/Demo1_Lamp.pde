////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  //<>//
/////////////////////////////////////////////////* VARIABLES --> CHANGE WHERE NEEDED *//////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* --> */final static String HUE_KEY  = "kD77WcV2Dnvx699aE1Fgm8I5Mnarc5JJE033S1M4";              // username Hue Developer (according to Bridge)
/* --> */final static String HUE_IP   = "192.168.1.140";            // IP adress Hue Bridge
/* --> */final static int SERVER_PORT = 1755;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_1_1 = 1755;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_1_2 = 1756;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_1 = 1788;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_2 = 1789;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int Watches = 2;
/* --> */final static int num_targets = 6;                               // amount of current targets
/* --> */boolean useServer = false;                                       // set to true if you are / want to be connected over WIFI
/* --> */boolean useHUE = false;                                       // set to true if you are / want to be connected over WIFI
/* --> */boolean withWatch = false;                                       // false for target testing
/* --> */int[][] HUES = {                     // Philips HUE lights to be used 
/* --> */  {1, 50, 255, 0, 0}                 // Respectively the Lights ID,  HUE, SATURATION and BRIGHTNESS
/* --> */  //{2, 50, 255, 0, 0},              // add more if wanted. Do adjust the 'act upon winner' section to get envisioned interaction
/* --> */  //{3, 50, 255, 0, 0}
/* --> */};  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import java.util.*;
import java.io.*;
import java.util.concurrent.ExecutorService;


///////////////////* OBJECTS AND THREADS *////////////////////////////////////////////////s/
ArrayList<Trial>    trialPackage     = null;    // Targets (class)
Correlator          correl           = null;    // Correlator (class)
Server              server           = null;    // Server for laptop <--> phone connection (class, initiates Thread)
adbThread           adb              = null;    // ADBThread for phone --> laptop sensor USB connection                   
hueThread           hueT             = null;    // Thread for, if needed, updates to Philips HUE sets
String              tagName = "ChannelThread";  // tag to search for in ADB messages (USB)
String adbPath;                                 // where to find adb executable; set in setup. YOU WILL NEED ENTER THIS FOR YOUR SYSTEM

boolean adb_running = false;           // Is the ADB thread running?  Yes or no?
boolean socket_running = false;
boolean package_started = false;

int STATE = 0;


///////////////////* SCREEN & PROPERTIES */////////////////////////////////////////////////
float PPI = 89;                      // iMac 21.5": 102.46, Callisto: 220, Tablet: ?, Macbook Pro 15": 221
float PPCM = PPI/2.54;               // Pixel density
float VDEGREE = .63*PPCM;            //
float CENTERX, CENTERY;
float TARGET_SIZE = 1.2 * PPCM;
PImage icon1, icon2, icon3, photoframe;
boolean scene1 = false, scene2 = false, scene3 = false;
int scene_animate = 30;
final int scene_animate_ini = 50;
int start_count = 255;              // slowly fades the 'picture' into the screen

///////////////////* PHILIPS HUE REQUIREMENTS */////////////////////////////////////////////////
int last_winner, winner_buffer_ini = 10;    // req. for buffer for gaps in selection (better UX, not better performance)
int[] winner_buffer = new int[num_targets];
ArrayList<Integer> selection = new ArrayList<Integer>(Watches);
ArrayList<Integer> winner = new ArrayList<Integer>(Watches);
boolean updateHUE;                   // toggle need for Philips hue update on/off


long max_disconnect = 1000;          // maximum time for no ADB data before alert
boolean watchConnected = true;       // toggle to switch visuals when 'alert'

boolean demoStarted = false, demoPaused = false;
boolean firsttime = true;

final int TRIAL_TIME    =   50000;          // 4000 < 17 minutes per source; 5000 ~ 19 minutes per source
final int WINDOWSIZE    =    292;          // a correlation window of 292 datapoints (at least 1.5 seconds)
//final int WINDOWSIZE    =    90;          // a correlation window of 292 datapoints (at least 1.5 seconds)

PFont myFont;



int FRAMERATE = 40;                      // for drawing

ArrayList<ArrayList<Long>>                  systemTime, androidTime;
ArrayList<ArrayList<ArrayList<Float>>>      targetXs, targetYs;
ArrayList<ArrayList<Long>>                  watchTimestamps;
ArrayList<ArrayList<Integer>>               watchSensorID, watchSensorFlipped, watchAccuracy;
ArrayList<ArrayList<Float>>                 watchYaw = null, watchRoll = null, watchPitch = null;

String ss = "small", sm = "medium", sb = "big";
String xll = "leftleft", xl = "left", xm = "mid", xr = "right", xrr = "rightright";
String yt = "top", ym = "mid", yl = "bottom";

/*
float SPACE = 2.3;
 int SIZE_SMALL = 4;          // 2cm / 0.996 deg.
 int SIZE_MEDIUM = 6;          // 12cm  / 5.973 deg.
 int SIZE_WIDE = 8;            // 24cm  / 11.914 deg.
 */

float SPACE = 6.9;
int SIZE_SMALL = 6;          // 2cm / 0.996 deg.
int SIZE_MEDIUM = 10;          // 12cm  / 5.973 deg.
int SIZE_WIDE = 16;            // 24cm  / 11.914 deg.

int LOW_SPEED = 90;           // 90 deg./sec
int MED_SPEED = 180;          // 180 deg./sec
int HIGH_SPEED = 270;         // 360 deg./sec
int VERY_HIGH_SPEED = 360;    // 360 deg./sec

int LOWEST_AMOUNT = 2;
int LOW_AMOUNT = 4;
int MED_AMOUNT = 8;
int HIGH_AMOUNT = 12;
int HIGHEST_AMOUNT = 16;

//     FINAL SET!
int[] SIZE_ARR = {SIZE_SMALL, SIZE_MEDIUM, SIZE_WIDE};
int[] SPEED_ARR= {LOW_SPEED, MED_SPEED, HIGH_SPEED, VERY_HIGH_SPEED};
int[] AMOUNT_ARR = {LOWEST_AMOUNT, LOW_AMOUNT, MED_AMOUNT, HIGH_AMOUNT, HIGHEST_AMOUNT};
int HAND_CHECK = -1;       // uneven participants start with DOM, even with NON DOM

int MAX_TARGETS = HIGHEST_AMOUNT;

// use a single global clock
long currentStudyTime, countDownStarted, trialStarted, finishedStudyTime, last_adb_time;
long old_currentST = 0;
boolean recording_data, flipped, finishedStudy, paused, trial_succes, instruction;
int finishedFirstStudy = 0;
PFont headerFont, counterFont;
private DefaultHttpClient httpClient; // http client to send/receive data

float yaw, pitch, roll;

void setup()
{
  fullScreen();
  //size(800, 480);
  rectMode(CENTER);
  ellipseMode(CENTER);
  frameRate(FRAMERATE);

  icon1 = loadImage("assets/icon1.png");
  icon2 = loadImage("assets/icon2.png");
  icon3 = loadImage("assets/icon3.png");
  photoframe = loadImage("assets/photoframe.jpg");

  myFont = createFont("Arial Bold", 32);
  textFont(myFont);

  correl = null; 

  if (useServer) {
    server = new Server();
    server.start();
  }

  registerMethod("dispose", this); // register a close event to quit the adb thread. 

  if (useHUE)
    startHueT();





  CENTERX = width / 2;
  CENTERY = height / 2;
}

void initStudy()
{
  currentStudyTime = System.currentTimeMillis();
  finishedStudyTime = 0;

  last_winner = -15;

  selection = new ArrayList<Integer>(Watches);
  winner_buffer = new int[num_targets];

  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;

  for (int i = 0; i < Watches; i++)
    selection.add(-13);


  finishedStudy = false;
  paused = false;

  countDownStarted = currentStudyTime;
  trialStarted = 0;

  headerFont = createFont("Monospaced", 24, true); 
  counterFont = createFont("Monospaced", 200, true);

  recording_data = false;
  trial_succes = false;
  flipped = false;

  makeTrialPackage();      // compile all trials in one package;
  prepareTrial();          // add correlator and initialize and empty variables

  if (withWatch)
    correl = new Correlator(trialPackage.get(0).targets.size(), WINDOWSIZE, 0.8);
}

void draw()
{
  background(0);  

  if (demoStarted)
  {
    if (!demoPaused && start_count>=0) {
      start_count -= ((int)((255-start_count)/15)+1);
      constrain(start_count, 0, 255);
    }
    runStudy();
  } 
  if (demoPaused)
  {
    if (start_count <=255) {
      adb_running = false;
      start_count += ((int)((255-start_count)/15)+1);
      constrain(start_count, 0, 255);
    }
    if (start_count==255) {
      demoPaused = false; 
      demoStarted = false;       
      //server.startADB(1);
    }
  } 

  if (start_count >0 ) 
    //println("Startcount: " + start_count);
    tint(150);
  image(photoframe, map(start_count, 0, 255, width, 0), 0, width, height);
  tint(255);
}


void runStudy()
{
  currentStudyTime = System.currentTimeMillis();

  if (trialStarted != 0)     // We are in a trial screen
  {

    if (useServer) {
      if ((server.server_running.get(1)) || (server.server_running.get(3))) {
        actUponWinner();
      }
    }
    drawStatus();                       // draw status Light(s)
    drawTargets();                      // UPDATE targets AND DRAW

    if (watchConnected) {  // stop the trial and call the researcher!
      recording_data = true;
    }
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
    for (int i =0; i<num_targets; i++)
    {
      if (winner.contains(i)) {                                        // indicate direct selection vs continuous
        trialPackage.get(0).targets.get(i).targetSelected(20);      // give border width
        winner_buffer[i] = winner_buffer_ini;
      } else { 
        trialPackage.get(0).targets.get(i).targetSelected(0);      // give border width
      }
    }
    for (int temp_winner : winner) {
      println(temp_winner);
      if (temp_winner>=0) {
        switch(temp_winner) {

        case 0:      // HUE --
          HUES[0][1]-= 1;
          if (HUES[0][1] < 0) HUES[0][1] += 255;
          break;
        case 1:      // Bri ++
          HUES[0][3]= constrain(HUES[0][3]+1, 0, 254);
          break;  
        case 2:      // bri --
          HUES[0][3]= constrain(HUES[0][3]-1, 0, 254);
          break;
        case 3:      // SCENE 1 : READING
          HUES[0][1] = (int) map(46, 0, 360, 0, 255);
          HUES[0][3] = 200;
          scene1 = true;
          restartCorrel();
          break;
        case 4:      // SCENE 2 : PIANO
          HUES[0][1] = (int) map(273, 0, 360, 0, 255);
          HUES[0][3] = 150;
          scene2 = true;
          restartCorrel();
          break;
        case 5:      // SCENE 3 : GAMES
          HUES[0][1] = (int) map(150, 0, 360, 0, 255);
          HUES[0][3] = 254;
          scene3 = true;
          restartCorrel();
          break;
        default:
          println("This shouldn't happen. Default in Switch");
          break;
        }

        updateHUE = true;
      }
    }
  }  
  for (int i = 0; i < winner_buffer.length; i++) {
    winner_buffer[i] = constrain(winner_buffer[i]-1, -1, winner_buffer_ini);   // always lower winner_buffer. recover if actual selection
    if (winner_buffer[i] < 0) {
      trialPackage.get(0).targets.get(i).targetSelected(0);      // remove all borders
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

  float icon1_x = trialPackage.get(0).targets.get(3).getTargetPos(now)[0];
  float icon1_y = trialPackage.get(0).targets.get(3).getTargetPos(now)[1];
  float icon2_x = trialPackage.get(0).targets.get(4).getTargetPos(now)[0];
  float icon2_y = trialPackage.get(0).targets.get(4).getTargetPos(now)[1];
  float icon3_x = trialPackage.get(0).targets.get(5).getTargetPos(now)[0];
  float icon3_y = trialPackage.get(0).targets.get(5).getTargetPos(now)[1];

  float size = 4.5;

  image(icon1, icon1_x-icon1.width/(2*size), icon1_y-icon1.height/(2*size), icon1.width/size, icon1.height/size);
  image(icon2, icon2_x-icon2.width/(2*size), icon2_y-icon2.height/(2*size), icon2.width/size, icon2.height/size);
  image(icon3, icon3_x-icon3.width/(2*size), icon3_y-icon3.height/(2*size), icon3.width/size, icon3.height/size);

  if (scene1 || scene2 || scene3) {
    float temp_x = -1000;
    float temp_y = -1000;
    if (scene1) {
      temp_x = icon1_x; 
      temp_y = icon1_y;
    }
    if (scene2) {
      temp_x = icon2_x; 
      temp_y = icon2_y;
    }
    if (scene3) {
      temp_x = icon3_x; 
      temp_y = icon3_y;
    }

    fill(255, map(scene_animate, scene_animate_ini, 0, 255, 50));
    ellipse(temp_x, temp_y, map(scene_animate, scene_animate_ini, 0, 0, SIZE_MEDIUM*VDEGREE), map(scene_animate, scene_animate_ini, 0, 0, SIZE_MEDIUM*VDEGREE));
    scene_animate--;
    if (scene_animate <= 0) {
      scene_animate = scene_animate_ini;
      scene1 = false;
      scene2 = false;
      scene3 = false;
    }
  }
}

void drawStatus() {
  colorMode(HSB, 255, 100, 100);

  /* -------------------------------- CIRCLES ------------------------ */

  // the big circle
  noFill();
  stroke(130);
  strokeWeight(6);
  ellipse(CENTERX-SPACE*VDEGREE, CENTERY, SIZE_WIDE*0.57*VDEGREE*2, SIZE_WIDE*0.57*VDEGREE*2);
  ellipse(CENTERX+SPACE*VDEGREE, CENTERY, SIZE_WIDE*0.57*VDEGREE*2, SIZE_WIDE*0.57*VDEGREE*2);
  noStroke();

  /* -------------------------------- DRAW BRIGHTNESS PIECHART ------------------------ */
  float brightness_x = CENTERX-SPACE*VDEGREE;
  float brightness_y = CENTERY;
  float brightness_r = 1.1 * SIZE_WIDE*VDEGREE / 2;

  noFill();
  fill(map(59, 0, 360, 0, 255), 100, map(HUES[0][3], 0, 255, 70, 100));
  translate(brightness_x, brightness_y);
  rotate(-HALF_PI);
  arc(0, 0, brightness_r*1.4, brightness_r*1.4, 0, map(HUES[0][3], 0, 254, 0, TWO_PI), PIE);
  rotate(HALF_PI);
  translate(-brightness_x, -brightness_y);
  fill(0);
  ellipse(brightness_x, brightness_y, brightness_r, brightness_r);

  /* -------------------------------- DRAW HUE PIECHART ------------------------ */

  float hue_x = CENTERX-SPACE*VDEGREE;
  float hue_y = CENTERY;
  float hue_r = 1.2 *SIZE_WIDE*VDEGREE / 2;

  color hueHSB_c = color(HUES[0][1], 100, 100);
  noFill();
  for (int i = 0; i < 40; i++) {
    color tempHUE = color(i*255/40, 75, 100);
    fill(tempHUE);
    arc(hue_x, hue_y, hue_r/1.4, hue_r/1.4, (i*TWO_PI/40)-(TWO_PI/100), ((i+1)*TWO_PI/40)+(TWO_PI/100), PIE);
  }

  fill(0);
  ellipse(hue_x, hue_y, brightness_r/2.5, brightness_r/2.5);
  fill(hueHSB_c);
  arc(hue_x, hue_y, hue_r/1.2, hue_r/1.2, map(HUES[0][1], 0, 254, 0, TWO_PI)-(PI/8), map(HUES[0][1], 0, 254, 0, TWO_PI)+(PI/8), PIE);
  fill(0);
  ellipse(hue_x, hue_y, brightness_r/3.2, brightness_r/3.2);
  colorMode(RGB);

  /* -------------------------------- PRESETS ------------------------ */

  float pres_x = CENTERX+SPACE*VDEGREE;
  float pres_y = CENTERY;

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(30);
  text("PRESETS", pres_x, pres_y);
}

void restartCorrel() {
  last_winner = -15;
  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;
  recording_data = false;
  prepareTrial();
  recording_data = true;
}

void keyReleased() 
{
  if (key == ' ' && !demoStarted) {
    demoStarted = true;
    demoPaused = false;
    initStudy();
  } else if (key == ' ' && demoStarted) {
    demoPaused = true;
  } else if (key == 't') {
    dispose();
    exit();
  } else if (key == 'r') {
    trialStarted = 0;
    countDownStarted = currentStudyTime;
    prepareTrial();
    correl = new Correlator(trialPackage.get(0).targets.size(), WINDOWSIZE, 0.8);
    watchConnected = true;
  } else if (useServer) {      // All messageing with the watch here
    if (key == '1') {
      server.sendMessage("1", 0);
    } else if (key == '2') {
      server.sendMessage("2", 0);
    } else if (key == '3') {
      server.sendMessage("3", 0);
    } else if (key == '4') {
      server.sendMessage("4", 0);
    } else if (key == 's') {
      if (!watchConnected)
        server.sendMessage("start_wearable", 0);
      if (watchConnected)
        server.sendMessage("stop_wearable", 0);
    }
  } else if (!withWatch) {
    if (key == CODED) {
      if (keyCode == RIGHT) {
        HUES[0][1]+= 10;
        if (HUES[0][1] >= 255) HUES[0][1] -= 255;
        updateHUE = true;
      } else if (keyCode == LEFT) {
        HUES[0][1]-= 10;
        if (HUES[0][1] < 0) HUES[0][1] += 255;
        updateHUE = true;
      } else if (keyCode == UP) {
        HUES[0][3]= constrain(HUES[0][3]+10, 0, 254);
        updateHUE = true;
      } else if (keyCode == DOWN) {
        HUES[0][3]= constrain(HUES[0][3]-10, 0, 254);
        updateHUE = true;
      }
    }
  }
} 


void stop()
{
  println("Closing sketch"); 
  if (watchConnected)
    server.sendMessage("stop_watch", 0);      // if adb breaks, make sure phone stops sending
  finishedStudy = true;
}

/*
 * Called on quit (via registerMethod) - clean up the thread
 */
public void dispose()
{
  if (useServer)
    server.sendMessage("stop_watch", 0);
  if (server!=null) {
    try {
      server.quit();
      println("quit server");
    } 
    catch (Exception e) {
      println(e.getMessage());
    }
  }
  if (hueT!=null)
    hueT.quit();
}

void startHueT() {
  if (hueT!=null)
    hueT.quit();
  hueT = new hueThread();
  hueT.start();
  updateHUE = true;
}
