////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  //<>// //<>//
/////////////////////////////////////////////////* VARIABLES --> CHANGE WHERE NEEDED *//////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* --> */final static int SERVER_PORT_1_1 = 1755;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_1_2 = 1756;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_1 = 1788;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int SERVER_PORT_2_2 = 1789;                        // port for socket connection over WIFI phone <--> laptop
/* --> */final static int Watches = 2;
/* --> */final static int num_targets = 6;                               // amount of current targets
/* --> */boolean useServer = false;                                       // set to true if you are / want to be connected over WIFI
/* --> */boolean withWatch = false;                                       // false for target testing

///////////////////* OBJECTS AND THREADS */////////////////////////////////////////////////
ArrayList<Trial>    trialPackage     = null;    // Targets (class)
Server              server           = null;    // Server for laptop <--> phone connection (class, initiates Thread)                   
String              tagName = "ChannelThread";  // tag to search for in ADB messages (USB)

ArrayList<ArrayList<Serie>>  series_row        = null;  //list containing all series within rows
PApplet thisGlobal = this;                              // reference to main PApplet
Movie runMovie = null; 

///////////////////* SCREEN & PROPERTIES */////////////////////////////////////////////////
float PPI = 89, PPCM = PPI/2.54, VDEGREE = .63*PPCM, CENTERX, CENTERY, TARGET_SIZE;                      // iMac 21.5": 102.46, Callisto: 220, Tablet: ?, Macbook Pro 15": 221
PImage user1, user2, user3, user4, userSelected, maskImage, up, down, play, pause, exit, logo, volumeIcon, soundIcon;                             
int  winner_buffer_ini = 10;    // req. for buffer for gaps in selection (better UX, not better performance)
int[] winner_buffer = new int[num_targets];

long max_disconnect = 1000;          // maximum time for no ADB data before alert

boolean demoPaused = false; // system turned 'off'

final int TRIAL_TIME    =   50000;          // 4000 < 17 minutes per source; 5000 ~ 19 minutes per source
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
long currentStudyTime, countDownStarted, trialStarted, finishedStudyTime, last_adb_time, waitCount, waitThres = 1500, prev_scroll_video, scroll_video_thres = 500;
long old_currentST = 0;
List<Integer> selection = new ArrayList<Integer>(Watches);
List<Integer> winner = new ArrayList<Integer>(Watches);
boolean recording_data, flipped, finishedStudy, paused, trial_succes, instruction;
int finishedFirstStudy = 0;
PFont headerFont, counterFont;

float yaw, pitch, roll;



///////////////////////////////////// SERIES /////////////////
int STATE = 0, nextSTATE = 0;      // off
float scroll_series = 0, scroll_video = 0;
;
int selected_row = 1;
float alpha = 256; // animation between states
boolean animate_1 = true, animate_2 = false; // for animation between states
Serie selectedSerie;
int selectedID = -3, newSelectedID = -1;

PFont AllerFont, AllerDisplay;

//MENU1
float userSize, titleSize, userTitleSize, posUser1, posUser2, posUser3, posUser4;
//MENU2
float posTitleImage, posTitle, posYear, posStars, posSubtext, posPlay, posExit, posScroll, sizeScroll, posUp, posDown, posLogo, posRow1, posRow2, posRow3, posGenre1, posGenre2, posGenre3, distLeft, distSerie;
float sizeTitle, sizeYear, sizeStars, sizeSubtext, sizePlay, sizeExit, sizeUp, sizeDown, sizeLogo, sizeRow1, sizeRow2, sizeRow3, sizeGenre1, sizeGenre2, sizeGenre3, widthRow, nr_rows, size_series;
// MENU3
float sizeScroll2, sizeProg, sizeInnerProg, sizeProgPoint, sizeVol, sizeVolText, sizePlay2, sizeDolby, sizeTime, widthProg, posDolby, posVol, posPlay2, strokeVol, posMenu, volume;
boolean movieRunning = false;
boolean menuToggle = false, wait = false;
;
float menuToggleCounter = 0, menuToggleCounterInit = 0;


int NR_SERIES;

void setup()
{
  fullScreen(JAVA2D);
  //size(1280, 720, JAVA2D);        // for testing, make everything half the size
  //size(1920,1080);
  //size(640, 360);
  rectMode(CENTER);
  ellipseMode(CENTER);
  frameRate(FRAMERATE);

  CENTERX = width / 2;
  CENTERY = height / 2;

  AllerFont = createFont("assets/AllerBold.ttf", 50);
  AllerDisplay = createFont("assets/AllerDisplay.ttf", 150);
  textFont(AllerFont);

  if (useServer) {
    server = new Server();
    server.start();
  }

  registerMethod("dispose", this); // register a close event to quit the adb thread. 

  applyScreenSize();
  loadImages();
  loadSeries();
}

void initStudy()
{
  currentStudyTime = System.currentTimeMillis();
  finishedStudyTime = 0;

  selection = new ArrayList<Integer>(Watches);
  winner = new ArrayList<Integer>(Watches);

  for (int i = 0; i < winner_buffer.length; i++)
    winner_buffer[i] = 0;

  for (int i = 0; i < Watches; i++)
    selection.add(-13);

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
  switch (STATE) {
  case 0:
    drawSTATE0();
    break;
  case 1:
    drawSTATE1();
    break;
  case 2:
    drawSTATE2();
    break;
  case 3:
    drawSTATE3();
    break;
  default:
    break;
  }
  drawSTATEtransition();
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
    if (useServer) {
      if ((server.server_running.get(1) || server.server_running.get(3)) && currentStudyTime-waitCount>waitThres) {
        actUponWinner();
      }
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
    for (int i =0; i<num_targets; i++)
    {
      if (winner.contains(i)) {                                        // indicate direct selection vs continuous
        trialPackage.get(STATE).targets.get(i).targetSelected(7);      // give border width
        winner_buffer[i] = winner_buffer_ini;
      } else { 
        trialPackage.get(STATE).targets.get(i).targetSelected(0);      // give border width
      }
    }
    switch(STATE) {
    case 0:  //nothing, no menu is present
      break;
    case 1:  // user selection screen // any winner will go to next screen
      Collections.shuffle(winner);      // no preference
      for (int temp_winner : winner) {
        if (!wait) {                   // if a discrete actions is initiated, do not interfere
          switch(temp_winner) {        // officially no preference, now quick implementation of maximum selected
          case 0:      
            userSelected = user1;
            animate_1 = true;
            nextSTATE = 1;
            break;
          case 1:     
            userSelected = user2;
            animate_1 = true;
            nextSTATE = 1;
            break;  
          case 2:      
            userSelected = user3;
            animate_1 = true;
            nextSTATE = 1;
            break;
          case 3:      
            userSelected = user4;
            animate_1 = true;
            nextSTATE = 1;
            break;
          default:
            //println("This shouldn't happen. Default in Switch MENU 1");
            break;
          }
        }
      }
      break;
    case 2:
      Collections.shuffle(winner);      // no preference
      for (int temp_winner : winner) {
        if (!wait) {
          if (temp_winner >= 0) {
            switch(temp_winner) {
            case 0: 
              scroll_series-=5;
              break;
            case 1:     
              scroll_series+=5;
              break;  
            case 2:      
              wait = true;
              restartCorrel();
              adjustSeries(-1);
              break;
            case 3:   
              wait = true;
              restartCorrel();
              adjustSeries(1);
              break;
            case 4: 
              animate_1 = true;
              nextSTATE = 1;
              break;
            case 5:      
              animate_1 = true;
              nextSTATE = -1;
              break;
            default:
              println("This shouldn't happen. Default in Switch MENU 2");
              break;
            }
          }
        }
      }
      break;
    case 3:
      Collections.shuffle(winner);      // no preference
      for (int temp_winner : winner) {
        if (!wait) {
          if (temp_winner >= 0) {
            switch(temp_winner) {
            case 0: 
              scroll_series+=0.25;
              break;
            case 1:     
              scroll_series-=0.25;
              break;  
            case 2:      
              volume=constrain(volume+=0.005, 0f, 1f);
              break;
            case 3:   
              volume=constrain(volume-=0.005, 0f, 1f);
              break;
            case 4: 
              wait = true;
              restartCorrel();
              if (movieRunning) {
                runMovie.pause();
                movieRunning = false;
              } else {
                runMovie.play();
                movieRunning = true;
              }
              break;
            case 5:      
              wait = true;
              animate_1 = true;
              runMovie.jump(0);
              nextSTATE = -1;
              break;
            default:
              println("This shouldn't happen. Default in Switch MENU 2");
              break;
            }
          }
        }
      }
      break;
    default:
      break;
    }
  }
  for (int i = 0; i < winner_buffer.length; i++) {
    winner_buffer[i] = constrain(winner_buffer[i]-1, -1, winner_buffer_ini);   // always lower winner_buffer. recover if actual selection
    if (winner_buffer[i] < 0) {
      trialPackage.get(STATE).targets.get(i).targetSelected(0);      // remove all borders
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
  trialPackage.get(STATE).updatePos(now); 
  trialPackage.get(STATE).draw();
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
    if (key == 'w') {
      animate_1 = true;
      nextSTATE = 1;
    } else if (key == 's') {
      animate_1 = true;
      nextSTATE = -1;
    } else if (key == 'm') {
      menuToggle = !menuToggle;
    }
    if (key == CODED) {
      if (STATE == 3) {
        if (keyCode == RIGHT) {
          scroll_series-=10;
        } else if (keyCode == LEFT) {
          scroll_series+=10;
        } else if (keyCode == UP) {
          volume=constrain(volume+=0.02, 0f, 1f);
        } else if (keyCode == DOWN) {
          volume=constrain(volume-=0.02, 0f, 1f);
        }
      } else {
        if (keyCode == RIGHT) {
          scroll_series-=10;
        } else if (keyCode == LEFT) {
          scroll_series+=10;
        } else if (keyCode == UP) {
          adjustSeries(-1);
        } else if (keyCode == DOWN) {
          adjustSeries(1);
        }
      }
    }
  }
} 

void switchState(int add) {
  if (STATE == 3 && add == -1) {
    runMovie.pause();
    if (useServer)
      for (int i = 0; i < Watches; i++) {
        if (server.server_running.get(1+i*2)) {
          server.sendMessage("/movie_stop", i*2);
        }
      }
  }
  switch(constrain(STATE + add, 0, 3)) {
  case 0:            // off
    demoPaused = false;
    initStudy();
    break;
  case 1:            // who's watching?
    demoPaused = false;
    initStudy();
    break;            // choose series
  case 2:
    iniSeries();
    adjustSeries(-9);
    showSelectedSerie();
    demoPaused = false;
    initStudy();
    break;
  case 3:          // watch movie
    menuToggle = false;
    if (useServer) {
      for (int i = 0; i < Watches; i++) {
        if (server.server_running.get(1+i*2)) {
          server.sendMessage("/movie_start", i*2);
        }
      }
    }
    runMovie = selectedSerie.get_movie();
    movieRunning = true;
    //runMovie = new Movie(thisGlobal,series_row.get(0).get(0).get_loc());
    runMovie.play();
    break;  
  default:
    break;
  }
  STATE = constrain(STATE + add, 0, 3);
  println("state is: " + STATE);
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

void movieEvent(Movie m) { 
  m.read();
} 

void checkConnection() {
  Boolean temp = true;
  if (useServer) {
    for (int i = 0; i < Watches; i++) {
      if (server.server_running.get(1+(i*2))) {      // only the ADB servers
        temp = false;
        return;
      }
    }
  }
  demoPaused = temp;
}
