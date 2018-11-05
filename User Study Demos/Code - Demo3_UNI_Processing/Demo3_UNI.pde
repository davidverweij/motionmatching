////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  //<>//
/////////////////////////////////////////////////* VARIABLES --> CHANGE WHERE NEEDED *//////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* --> */final static int SERVER_PORT_1_1 = 1755;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_1_2 = 1756;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_1 = 1788;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_2 = 1789;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int Watches = 2;
/* --> */boolean useServer = true;                                       // set to true if you are / want to be connected over WIFI
/* --> */boolean withWatch = useServer;                                       // false for target testing

///////////////////* OBJECTS AND THREADS */////////////////////////////////////////////////
ArrayList<Trial>    trialPackage     = null;    // Targets (class)
ArrayList<Trial>    trialPackageAdd  = null;    // fake targets
Server              server           = null;    // Server for laptop <--> phone connection (class, initiates Thread)                   
String              tagName = "ChannelThread";  // tag to search for in ADB messages (USB)


///////////////////* SCREEN & PROPERTIES */////////////////////////////////////////////////
float PPI = 89, PPCM = PPI/2.54, VDEGREE = .63*PPCM, CENTERX, CENTERY, TARGET_SIZE;                      // iMac 21.5": 102.46, Callisto: 220, Tablet: ?, Macbook Pro 15": 221         
int  winner_buffer_ini = 10;    // req. for buffer for gaps in selection (better UX, not better performance)
int[] winner_buffer = new int[8];    //max number of targets. Will be reset when new menu.

long max_disconnect = 1000;          // maximum time for no ADB data before alert

boolean demoPaused = false, resultQ = false; // system turned 'off'

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
long currentStudyTime, countDownStarted, trialStarted, finishedStudyTime, 
  last_adb_time, begin_question_time = 0, 
  begin_question_thres = 120000 /* two minutes max */, transition_time=0, transition_time_thres = 4800;
long old_currentST = 0;
List<Integer> selection = new ArrayList<Integer>(Watches);
List<Integer> winner = new ArrayList<Integer>(Watches);
List<Integer> objective = new ArrayList<Integer>(Watches);
boolean recording_data, flipped, finishedStudy, paused, trial_succes, instruction, begin_question = false, transition =false, showQ = false, showA=false;
;
int finishedFirstStudy = 0, STATE = 0, newSTATE = 0, oldSTATE = 0;
float yaw, pitch, roll;

///////////////////////////////////// QUESTIONS /////////////////

float questionNrX, questionX, questionY, Q1_topLeftX, Q1_topLeftY, Q1_topRightX, Q1_targetDist, 
  Q1_targetSize, Q2_targetSize, Q2_targetY, questionNrSize, questionSize, answerSize, Q1R_L, Q3_targetSize, Q3_targetY, 
  animation = 0, answerSize2, Q4_diff, timeStroke, timeStrokeHeight;
String[] questions = new String[5], answers1 = new String[6], answers3 = new String[4], instructions1 = new String[5], instructions2 = new String[5];
int[][] results, results_prev;
int[] results_correct;
color WT = color(0, 161, 131), WTlight = color(207, 229, 225), WTred = color (211, 20, 0);
PFont AllerItalic, AllerBold, Aller, AllerDisplay;
PImage logo, background;
PImage[] Q4_image;
int Q4_size;

void setup()
{
  fullScreen(JAVA2D);
  //size(1280, 720, JAVA2D);        // for testing, make everything half the size
  //size(1920,1080);1
  //size(640, 360);
  ellipseMode(CENTER);
  frameRate(FRAMERATE);

  CENTERX = width / 2;
  CENTERY = height / 2;

  Aller = createFont("assets/Aller_Rg.ttf", 50);
  AllerBold = createFont("assets/AllerBold.ttf", 50);
  AllerDisplay = createFont("assets/AllerDisplay.ttf", 150);
  AllerItalic = createFont("assets/Aller_It.ttf", 50);
  textFont(Aller);

  logo = loadImage("assets/wavetraceUNI.png");
  background = loadImage("assets/background.jpg");

  if (useServer) {
    server = new Server();
    server.start();
  }

  registerMethod("dispose", this); // register a close event to quit the adb thread. 

  applyScreenSize();

  Q4_image = new PImage[6];
  for (int i = 1; i<=6; i++) {
    Q4_image[i-1] = loadImage("assets/PP" + i + ".png");
    Q4_image[i-1].resize(Q4_size, Q4_size);
  }

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
    objective.add(-13);
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

  if (useServer) {
    for (int i = 0; i < Watches; i++) {
      if (server.server_running.get(i*2)) {
        server.sendMessage("/classroom_start", i*2);
      }
    }
  }
}

void draw()
{
  drawQuestion_part1(STATE, resultQ);

  checkConnection();
  if (!resultQ && !transition && begin_question) runStudy();
  drawQuestion_part2(STATE, resultQ);

  if (withWatch) {          // communication to watches
    if (STATE != oldSTATE) {      //if new STATE, act...

      selection = new ArrayList<Integer>(Watches);
      objective = new ArrayList<Integer>(Watches);
      for (int i = 0; i < Watches; i++) {      //empty answers (they are stored in 'results[][]'
        selection.add(-13);
        objective.add(-13);
        results[STATE][i] = -13;
        results_prev[STATE][i] = -13;
      } 

      switch(STATE) {
      case 0:      // intro menu
        transition = false;
        sendBreak();
        break;
      case 1:      // first question, watches should be able to provide input
        sendQuestion();
        break;
      case 2:      // second question, watches should be able to provide input
        sendQuestion();
        break;
      case 3:      // third question, assign 'random' colour to watches and allow for input
        for (int i = 0; i < objective.size(); i++)
          objective.set(i, int(random(2, 6)));
        sendQuestion();
        break;
      case 4:      // fourth question, assign 'random' political party to watches, allow for input
        for (int i = 0; i < objective.size(); i++)
          objective.set(i, int(random(6, 12)));        
        sendQuestion();
        break;
      }
    }
    oldSTATE = STATE;
  }
}


void runStudy()
{
  currentStudyTime = System.currentTimeMillis();

  if (trialStarted != 0)     // We are in a trial screen
  {
    if (withWatch)
      if ((server.server_running.get(1) || server.server_running.get(3))) {
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
  for (int i = 0; i < winner.size(); i++) {
    switch(STATE) {
    case 0:
      // there should be no data at the intro screen. To check print line below. Should not happen.
      //println("This shouldn't happen. winner in STATE 0");
      break;
    case 1:
      if (winner.get(i)>=0) {
        results[STATE][i] = winner.get(i);
      }
      break;
    case 2:
      if (winner.get(i)>=0) {
        results[STATE][i] = winner.get(i);
      }
      break;
    case 3:
      if (winner.get(i)>=0) {
        results[STATE][i] = (winner.get(i)+4-(objective.get(i)-2))%4;        // make sure the selection (only green) is translated to the colour the student(s) get(s)
      }
      break;
    case 4:
      if (winner.get(i)>=0) {
        results[STATE][i] = winner.get(i);
        results[STATE+1][i] = objective.get(i)-6;      // last question has additional row for objective (political parties)
      }
      break;
    default:
      println("This shouldn't happen. Default in switch STATE actuponWinner");
      break;
    }
  }


  // results will be shown / question stopped when all watches have answered, or when teacher presses button
  int answers = 0;
  for (int i = 0; i<winner.size(); i++) {
    if (winner.get(i) >= 0) answers++;
    if (results[STATE][i] != results_prev[STATE][i]) {    //send selection confirmation if selected new or different answer
      results_prev[STATE][i] =  results[STATE][i]; // store
      println("new selection!");
      sendSelect(i);
    }
  }
  if (answers == winner.size()) {      // everyone has answered
    resultQ = true;
    begin_question = false;
    sendBreak();
    if (STATE != 4)
      sendResults();
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
      targetXs.               add(new ArrayList<ArrayList<Float>>(trialPackage.get(newSTATE).targets.size()));    // arraylist of arraylists
      targetYs.               add(new ArrayList<ArrayList<Float>>(trialPackage.get(newSTATE).targets.size()));
      watchTimestamps.        add(new ArrayList<Long>());
      watchSensorID.          add(new ArrayList<Integer>());
      watchSensorFlipped.     add(new ArrayList<Integer>());
      watchAccuracy.          add(new ArrayList<Integer>());
      watchYaw.               add(new ArrayList<Float>());
      watchRoll.              add(new ArrayList<Float>());
      watchPitch.             add( new ArrayList<Float>());

      for (int i = 0; i < trialPackage.get(newSTATE).targets.size(); i++) {                                     // initialize the second dimension of arraylists
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
  trialPackage.get(STATE).updatePos(now); 
  trialPackage.get(STATE).draw();
  if (STATE == 3) {
    for (int i = 0; i<trialPackageAdd.size(); i++) {
      trialPackageAdd.get(i).updatePos(now);
      trialPackageAdd.get(i).draw();
    }
  }
}

void restartCorrel() {
  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;

  recording_data = false;
  prepareTrial();
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
  } else if (key == 's') {
    if (transition)
      showQ = true;
    else if (begin_question) {
      resultQ = !resultQ;
      sendBreak();
      if (STATE !=4)
        sendResults();
    } else {
      showA = true;
    }
  } else if (key == '0' ||key =='1' || key == '2' || key == '3' || key == '4') {
    if (key == '0') newSTATE = 0;
    else if (key == '1') newSTATE = 1;
    else if (key == '2') newSTATE = 2;
    else if (key == '3') newSTATE = 3;
    else if (key == '4') newSTATE = 4;
    if (STATE != newSTATE) {
      restartCorrel();
      resultQ = false;
    }
    STATE = newSTATE;
    recording_data = true;
    transition=true;
    transition_time = 0;
    showA = false;
    showQ = false;
    resultQ = false;
  } else if (key == CODED) {
    if (keyCode == RIGHT) {
    } else if (keyCode == LEFT) {
    } else if (keyCode == UP) {
      newSTATE = constrain(STATE+1, 0, 4);
      if (STATE != newSTATE) {
        restartCorrel();
        resultQ = false;
      }
      begin_question = false;
      STATE = newSTATE;
      recording_data = true;
      transition=true;
      transition_time = 0;
      showA = false;
      showQ = false;
    } else if (keyCode == DOWN) {
      newSTATE = constrain(STATE-1, 0, 4);
      if (STATE != newSTATE) {
        restartCorrel();
        resultQ = false;
      }
      begin_question = false;
      STATE = newSTATE;
      recording_data = true;
      transition=true;
      transition_time = 0;
      showA = false;
      showQ = false;
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
  for (int i = 0; i < 5; i++)
    for (int q = 0; q < Watches; q++)
      printArray(results[i][q]);

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

void sendBreak() {
  if (withWatch) 
    for (int i = 0; i < Watches; i++) 
      if (server.server_running.get(i*2)) 
        server.sendMessage("/classroom_break", i*2);
}
void sendQuestion() {
  if (withWatch) 
    for (int i = 0; i < Watches; i++) 
      if (server.server_running.get(i*2)) {
        if (newSTATE == 1 || newSTATE == 2) server.sendMessage("/wavetrace_show_button_99", i*2);    //remove any displays
        else server.sendMessage("/wavetrace_show_button_"+objective.get(i), i*2);                    // show objective, effectively removing otherdisplays

        server.sendMessage("/classroom_question", i*2);
      }
}
void sendSelect(int watch) {
  if (withWatch) 
    if (server.server_running.get(watch*2)) 
      server.sendMessage("selection", watch*2);
}
void sendResults() {
  if (withWatch) 
    for (int i = 0; i < Watches; i++) 
      if (server.server_running.get(i*2)) {
        if (STATE > 0 && STATE <4) {
          if (results[STATE][i] == results_correct[STATE]) {
            server.sendMessage("/wavetrace_show_button_"+1, i*2);      //correct
          } else {
            server.sendMessage("/wavetrace_show_button_"+0, i*2);      //wrong
          }
        } else if (STATE == 4) {
          if (results[STATE][i] == results[STATE+1][i]) {
            server.sendMessage("/wavetrace_show_button_"+1, i*2);      //correct
          } else {
            server.sendMessage("/wavetrace_show_button_"+0, i*2);      //wrong
          }
        }
      }
}