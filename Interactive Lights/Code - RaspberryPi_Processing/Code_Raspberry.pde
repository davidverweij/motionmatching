/*
 * This sketch consists out of four parts
 *   1) the tab 'Targets' contains the 'formulas' for all the possible targets, depending on current STATE and based on millis(): the time since the device is powered up. 
 *   2) The main thread (void draw) is used to visualize the positions of the 'active' targets (OPTIONAL), and sends the corresponding LED instructions to the ESP's, thus the framerate determines the 'refreshrate' of the lights.
 *   3) The ESPcom is a UDP service that sends the LED instructions to the lights, at the speed of the framerate. It also initiates a UDP (seperate) thread to listen to the incoming motion data from the watch.
 *   4a) The WATCHcom is a dedicated thread that listens to any incoming UDP messages from the watch. It is seperate, to receive data at the highest speed and is not bound to the refreshrate.
 *   4b) This thread also stores and correlates the motion data and target data from the last 2 (variable) minutes to determine any selection and (if so) corresponding LED or STATE change.
 *
 *  NOTE: the IP Adresses of the raspberry PI and Lamps are fixed, as this then does not require any handshake method (easier), though the network needs to have them made static (see in the code) 
 */

boolean simulation = false;         // true = keyboard input, false = watch input
int numberKEYBOARD = -9;            // to simulate de-selection by keypresses

int STATE = 0;                      // STATES: 0 = all lights IDLE, 1 = light 1 SELECTED, 2 = light 2 SELECTED .... etc   

button viewStat, viewTargets, simulationButton;       // UI to toggle visuals
button[] lamps;                     // UI to toggle visuals
boolean udpWATCH_running = false;   // boolean that can shut down the WATCHcom thread
boolean recording_data = true;      // turn of before state change. WATCHcom THREAD will turn it back on: Safety feature that prevent accidental correlation with null data
boolean lampToggle = false;         // if a new lamp is added to the demo (or removed) the watchUDP needs to reset.
boolean incomingWatch = false;      // indicator of incoming Watch messages
long last_incomingWatch = 0;        // keep track of last time message was send!

// LAMP VARIABLES
float[][][] LEDstrips;              // [led strips] [ammount of leds] [R][G][B][W]
int numLEDstrips;                   // equals number of lights
int[] add_angle = {270, 315, 0};    // to adjust for position of first LED depending on lamp design. radian begins left, LED strips begins bottom / bottomright (light 2) or even top (light 3);
int[] lightPARAM = {20, 2, 0};      // [0] = width of beam walllight (0 - LEDstrips[0].length-2), [1] standmode : 0 = all lights on, 1 = top lights on, 2 = bottom lights on, 3 = off; [3] -75 = cold white --> 75 = warm white
float[] brightness = {100, 100, 100}; // brightness of the lights. Changed using 'roll' (and pitch/yaw stable). 0 - 100% (255)


void setup() {
  size(700, 400);                   // SOMEHOW the raspberry PI 3 runs smoother in NOT fullscreen. 
  frameRate(30);                    // for visualisation AND the refreshrate over UDP for the ESP. 30 = the resolution of the LED strips at speed: 180 (don't go lower)
  textAlign(CENTER); 

  viewStat = new button("Toggle Status", width/6, 330, 100, 30, true);        // UI element. Toggle to show light status. DEFAULT: ON
  viewTargets = new button("Toggle Targets", width/2, 330, 100, 30, true);    // UI element. Toggle to show simulation targets. DEFAULT: ON
  simulationButton = new button("Toggle Simualtion", width-width/6, 330, 100, 30, false); // UI element. Toggle to use walllight in your demo! DEFAULT: OFF
  lamps = new button[3];
  lamps[0] = new button("USE WALLLIGHT IN DEMO", width/6, 25, 200, 30, false); // UI element. Toggle to use walllight in your demo! DEFAULT: OFF
  lamps[1] = new button("USE STANDLIGHT IN DEMO", width/2, 25, 200, 30, false); // UI element. Toggle to use walllight in your demo! DEFAULT: OFF
  lamps[2] = new button("USE CEILINGLIGHT IN DEMO", width-width/6, 25, 200, 30, false); // UI element. Toggle to use walllight in your demo! DEFAULT: OFF

  // LAMP CONFIGURATION: adjust where neccesary. Filling the arrays
  numLEDstrips = 3;
  LEDstrips = new float[numLEDstrips][][];
  LEDstrips[0] = new float[60][];                    // The wall lamp has 60 LEDS (1 meter)            
  LEDstrips[1] = new float[40-4][];                  // The standing lamp has 40 LEDS per module, though the two LED's in the corner act 'as one' (thus -4)
  LEDstrips[2] = new float[40][];                    // The ceiling lamp has 40 LEDS per module.
  for (int q = 0; q < LEDstrips.length; q++)         // Filling the arrays
    for (int i = 0; i < LEDstrips[q].length; i++)
      LEDstrips[q][i] = new float[]{0, 0, 0, 0};      // turn all LEDS off

  makeTargets();                    // create the targets
  registerMethod("dispose", this);  // register a close event to quit the adb thread and the main thread (this). 
  udpInit();                        // Init ESP (Lamps) UDP streaming
}

void draw() {
  background(0);
  viewStat.draw();                  // Draw button
  viewTargets.draw();               // Draw button
  simulationButton.draw();          // Draw button
  lamps[0].draw();                  // Draw button
  lamps[1].draw();                  // Draw button
  lamps[2].draw();                  // Draw button

  if (incomingWatch) {
    text("incoming watch message", width/2, height-15);
    if (millis()-last_incomingWatch>2000)  // don't show targets if the watch is not connected
      incomingWatch = false;      // will jitter all the time if average incoming speeds...
  }
  if (viewStat.on())                // If toggled, execute
    drawStatus();
  if (simulationButton.on())
    text("0, 1, or 2 to select lamp or targets, 9 for deslecting targets. LEFT or RIGHT to de/increase brightness", width/2, 15);
  if (STATE != 0)                   // If a lamp is selected (not STATE 0), then adjust targets if neccessary
    checkStatus();
  if (viewTargets.on())             // If toggled, execute
    showTargets(millis());  
  sendLED();                        // Update the connected Lamps (ESP)
}

void checkStatus() {          // turn targets on/off if needed (e.g. if maximum is achieved, the target to in/de-crease is removed visually in the lights (not in simulation, as it has no effect either way)
  if (lightPARAM[0] == LEDstrips[0].length-2)             // Walllight is maximum ON
    Lights.get(0).get(1).targets.get(1).setColor(0);      // turn INCREASE target off
  else                                                    // Walllight is NOT maximum ON
  Lights.get(0).get(1).targets.get(1).setColor(1);        // turn INCREASE target on
  if (lightPARAM[0] == 0)                                 // Walllight is maximum OFF
    Lights.get(0).get(1).targets.get(0).setColor(0);      // turn DECREASE target off
  else                                                    // Walllight is NOT maximum OFF
  Lights.get(0).get(1).targets.get(0).setColor(1);        // turn DECREASE target on

  for (int i = 0; i < 3; i++)                             // Turn all targets from the Standing light on
    Lights.get(1).get(1).targets.get(i).setColor(1);
  Lights.get(1).get(1).targets.get(lightPARAM[1]).setColor(0);    // Except for the current mode 

  if (lightPARAM[2] == 75)                                // Ceilinglight is maximum WARM-white
    Lights.get(2).get(1).targets.get(0).setColor(0);      // turn off INCREASE warmth
  else                                                    // Ceilinglight is NOT maximum WARM-white
  Lights.get(2).get(1).targets.get(0).setColor(1);        // turn on INCREASE warmth
  if (lightPARAM[2] == -75)                               // Ceilinglight is maximum COLD-white
    Lights.get(2).get(1).targets.get(1).setColor(0);      // turn off DECREASE warmth
  else                                                    // Ceilinglight is NOT maximum COLD-white
  Lights.get(2).get(1).targets.get(1).setColor(1);        // turn on DECREASE warmth
}

void sendLED() {      
  /* THIS FUNCTION TRANSLATES THE LAMP SPECIFIC VARIABLES IN THEIR CORRESPONDING LED STATES
   * First, we set the variables for the led strip to their correpsonding state
   * Then we add the target, effectively overrulling a LED setting in step 1
   * Then we send the completed variables (arrays) to their corresponding light/lamp
   */

  if (lamps[0].on()) {     // WALL LIGHT
    int size = LEDstrips[0].length;
    for (int i = 0; i < size; i++)                                 // setting light beam 'width'
      if (i>=lightPARAM[0]/2 && i<60-lightPARAM[0]/2) {            // if a LED is within the 'beam', turn it on, else off
        float temp[] = {0, 0, 0, brightness[0]*brightness[0]/255}; // use a quadratic effect of the brightness setting (LED's are not linearly brightened)
        LEDstrips[0][i] = temp;
      } else {
        float temp[] = {0, 0, 0, 0};
        LEDstrips[0][i] = temp;
      }
  }

  // STANDING LIGHT 
  // This light gets a special treatment, as the two LED's in the corners need to act the same, yet the sides must act as 1/4th of the square.
  // The target is simulated as a rotating target (two sine functions), though this is transfered to 4 diagonal sides
  // The ledstrip furthermore does not start at any corner, thus the following below might look a bit funny

  if (lamps[1].on()) {     
    int size = LEDstrips[1].length;
    for (int i = 0; i < size; i++)
    {
      LEDstrips[1][i][0] = 0;      // remove all colour {R,G,B,W}
      LEDstrips[1][i][1] = 0; 
      LEDstrips[1][i][2] = 0; 
      switch(lightPARAM[1]) {                                           // note: LED strip starts 1/8th back from bottom point, middle of bottom/right side rhomboid
      case 0:                                                           // If STATE = 0, all lights on
        LEDstrips[1][i][3] = brightness[1]*brightness[1]/255;           // Set all LED's on. (quadratic funtion to adjust for non-linear LEDbrightness)
        break;
      case 1:                                                           // If STATE = 1, bottom lights on
        if (i>=(int)((float)size/8*3) && i<(size-(int)((float)size/8))) // turn all LEDs in the top half OFF
          LEDstrips[1][i][3] = 0;
        else                                                            // and the others ON
        LEDstrips[1][i][3] = brightness[1]*brightness[1]/255;
        break;
      case 2:                                                           // If STATE = 2, top lights on
        if (i>=(int)((float)size/8*3) && i<(size-(int)((float)size/8))) // turn all LEDS in the top half ON
          LEDstrips[1][i][3] = brightness[1]*brightness[1]/255;
        else                                                            // and the others OFF
        LEDstrips[1][i][3] = 0;
        break;
      default:
        break;
      }
    }
  }

  // CEILING LIGHT   
  // in this light all LEDs are always on, yet their 'temperature' can be changed. This is simulated (as it is impossible with the LED strips) by adding red or blue.
  if (lamps[2].on()) {     // WALL LIGHT

    int size = LEDstrips[2].length;
    for (int i = 0; i < size; i++) {
      float lower = abs(constrain(lightPARAM[2], -75, 0))/3;        // divide by three as the effect was too strong
      float upper = abs(constrain(lightPARAM[2], 0, 75))/3;
      float temp[] = {lower*lower/25, 0, upper*upper/25, brightness[2]*brightness[2]/255};      // set the LEDs accordingly
      LEDstrips[2][i] = temp;
    }
  }

  /*
   *  Step 2: augment the targets, only if a watch is present
   */

  if (incomingWatch) {

    float support_dimmer = 0.0;         // brightness mulptiplier for the LEDs that surround the target. This increases their visibility. Change as you like (0.0 - 1.0)
    float target_normal_dimmer = 0.7;   // target brightness multiplier 
    float target_dimmer = 0.3;          // target brightness multiplier for target when no surrounding LEDS are on. This 'lowers' a targets brightness is it is not in a lit-area of the lamp. Between white LEDs it needs to be bright, but between dark/off LEDs it is too contrasting at full brightness.

    switch (STATE) {
    case 0:                                                                                  // all lights idle
      for (int q = 0; q < numLEDstrips; q++) {                                               // for each ledstrip/lamp
        if (lamps[q].on()) {                                                                 // if it is toggled 'on'
          int nr_targets = Lights.get(q).get(0).targets.size();                                // get the number of targets
          for (int i = 0; i < nr_targets; i++) {                                               // for each target
            float angle = Lights.get(q).get(0).targets.get(i).getTargetPos(millis())[0];       // get its position
            int LED = (int)((((angle+add_angle[q]+360)%360)/(360/LEDstrips[q].length)));       // making sure the angle is positive, and between 0 - 360, then translate onto the LED resolution (e.g. 60 or 40 LEDS)
            int previousLED = (LED+LEDstrips[q].length-1)%(LEDstrips[q].length);               // get the previous and..
            int nextLED = (LED+1)%(LEDstrips[q].length);                                       // next LED to lower their brightness (support_dimmer)

            float dimmer = target_normal_dimmer;                                               // if there are no white leds, lower the brightness, to merge target LED nicer
            if (LEDstrips[q][LED][3] == 0 || LEDstrips[q][previousLED][3] == 0 || LEDstrips[q][nextLED][3] == 0) 
              dimmer = target_dimmer; 
            color target = Lights.get(q).get(0).targets.get(i).getColor();                     // get the target colour from simulation
            float temp[] = {red(target)*dimmer, green(target)*dimmer, blue(target)*dimmer, 0}; // and apply accordingly to the LED variable

            if (target != color(0)) {                                                          // if the target is not presented, don't show
              LEDstrips[q][LED] = temp;                                                        // we can 'shut off' targets by making them black. To show controls more clearly (e.g. when you cannot add more yellow / brightness)

              if ((int)LEDstrips[q][previousLED][3] != 0) {                                    // don't overrule / kill another target
                LEDstrips[q][previousLED][0] = LEDstrips[q][previousLED][0]*support_dimmer;    // increase visibility by 'killing' the surrounding lights.
                LEDstrips[q][previousLED][1] = LEDstrips[q][previousLED][1]*support_dimmer;
                LEDstrips[q][previousLED][2] = LEDstrips[q][previousLED][2]*support_dimmer;
                LEDstrips[q][previousLED][3] = LEDstrips[q][previousLED][3]*support_dimmer;
              }
              if ((int)LEDstrips[q][nextLED][3] != 0)                                          // don't overrule / kill another target
                LEDstrips[q][nextLED][0] = LEDstrips[q][nextLED][0]*support_dimmer;            // increase visibility by 'killing' the surrounding lights.
              LEDstrips[q][nextLED][1] = LEDstrips[q][nextLED][1]*support_dimmer;
              LEDstrips[q][nextLED][2] = LEDstrips[q][nextLED][2]*support_dimmer;
              LEDstrips[q][nextLED][3] = LEDstrips[q][nextLED][3]*support_dimmer;
            }
          }
        }
      }
      break;
    case 1:          // busy with light 1: WALL. In case of either lamp is selected the following code will be executed. Which is almost similar as above, though differs for the standing light and focuses on one lamp
    case 2:          // busy with light 2: STANDING
    case 3:          // busy with light 3: CEILING

      int nr_targets = Lights.get(STATE-1).get(1).targets.size();                                  // get the number of targets
      for (int i = 0; i < nr_targets; i++) {                                                       // for each target
        float angle = Lights.get(STATE-1).get(1).targets.get(i).getTargetPos(millis())[0];         // get its position
        int LED = (int)((((angle+add_angle[STATE-1]+360)%360)/(360/LEDstrips[STATE-1].length)));   // making sure the angle is positive, and between 0 - 360, then translate onto the LED resolution (e.g. 60 or 40 LEDS)
        int previousLED = (LED+LEDstrips[STATE-1].length-1)%(LEDstrips[STATE-1].length);           // get the previous and..
        int nextLED = (LED+1)%(LEDstrips[STATE-1].length);                                         // next LED to lower their brightness (support_dimmer)
        float dimmer = target_normal_dimmer;                                                       // if there are no white leds, lower the brightness, to merge target LED nicer
        if (LEDstrips[STATE-1][LED][3] == 0 ) 
          dimmer = target_dimmer; 
        color target = Lights.get(STATE-1).get(1).targets.get(i).getColor();                       // get the target colour from simulation
        float temp[] = {red(target)*dimmer, green(target)*dimmer, blue(target)*dimmer, 0.0};       // and apply accordingly to the LED variable

        if (target != color(0)) {                                                                  // if the target is not presented, don't show
          LEDstrips[STATE-1][LED] = temp;                                                          // we can 'shut off' targets by making them black. To show controls more clearly (e.g. when you cannot add more yellow / brightness)

          if ((int)LEDstrips[STATE-1][previousLED][3] != 0) {                                      // don't overrule / kill another target
            LEDstrips[STATE-1][previousLED][0] = LEDstrips[STATE-1][previousLED][0]*support_dimmer;// increase visibility by 'killing' the surrounding lights.
            LEDstrips[STATE-1][previousLED][1] = LEDstrips[STATE-1][previousLED][1]*support_dimmer;
            LEDstrips[STATE-1][previousLED][2] = LEDstrips[STATE-1][previousLED][2]*support_dimmer;
            LEDstrips[STATE-1][previousLED][3] = LEDstrips[STATE-1][previousLED][3]*support_dimmer;
          }
          if ((int)LEDstrips[STATE-1][nextLED][3] != 0) {                                          // don't overrule / kill another target
            LEDstrips[STATE-1][nextLED][0] = LEDstrips[STATE-1][nextLED][0]*support_dimmer;        // increase visibility by 'killing' the surrounding lights.
            LEDstrips[STATE-1][nextLED][1] = LEDstrips[STATE-1][nextLED][1]*support_dimmer;
            LEDstrips[STATE-1][nextLED][2] = LEDstrips[STATE-1][nextLED][2]*support_dimmer;
            LEDstrips[STATE-1][nextLED][3] = LEDstrips[STATE-1][nextLED][3]*support_dimmer;
          }
        }
      }
      break; 
    default:
      break;
    }
  }

  if (lamps[0].on())
    sendData(deviceList.get(0), LEDstrips[0]);                            // Send the prepared LED array values to the corresponding light.
  if (lamps[1].on())
    sendData(deviceList.get(1), convertLamp2(LEDstrips[1]));
  if (lamps[2].on())
    sendData(deviceList.get(2), LEDstrips[2]);
}


float[][] convertLamp2(float[][] lamp2) {                               // because the corners are actually light up by 2 led's, we will insert them here.
  float[][] newLamp2 = new float[lamp2.length+4][4];
  for (int q = 0, i = 0; i < lamp2.length; q++, i++) {
    newLamp2[q] = lamp2[i];
    if (i == 4 || i == 13 || i == 22 || i == 31) {                      // the identified 1st LED of a corner
      newLamp2[q][3] = 0;
      if (lamp2[i][0] >0 || lamp2[i][1] >0 || lamp2[i][2] >0) {         // if coloured target (and in corner), set brightness down
        newLamp2[q][0] = lamp2[i][0]*.25;
        newLamp2[q][1] = lamp2[i][1]*.25;
        newLamp2[q][2] = lamp2[i][2]*.25;
      } 
      q++;
      newLamp2[q] = newLamp2[q-1];
      newLamp2[q][3] = 0;
    }
  }
  return newLamp2;
}


void keyPressed() {                    // FOR SIMULATION
  if (key == '0') {
    numberKEYBOARD = 0;
  } else if (key == '1') {
    numberKEYBOARD = 1;
  } else if (key == '2') {
    if (STATE == 2 || STATE == 0) numberKEYBOARD = 2;
  } else if (key == '9') {
    numberKEYBOARD = 9;
  }
  if (key == CODED) {
    if (keyCode == LEFT) {
      if (STATE != 0)
        brightness[STATE-1] = constrain(brightness[STATE-1]-5, 50, 255);
    } else if (keyCode == RIGHT) {
      if (STATE != 0)
        brightness[STATE-1] = constrain(brightness[STATE-1]+5, 50, 255);
    }
  }
}

void showTargets(long now) {
  if (STATE == 0) {                   
    for (int i = 0; i < numLEDstrips; i++) 
      if (lamps[i].on())
        Lights.get(i).get(0).draw(now);
  } else
    Lights.get(STATE-1).get(1).draw(now);
}


void drawStatus() {
  // BRIGHTNESS INDICATORS
  noStroke(); 
  fill(255); 
  textAlign(CENTER); 
  text(nf((float)brightness[0]/2.55, 3, 1)+"%", width/6, height/2); 
  text(nf((float)brightness[1]/2.55, 3, 1)+"%", width/2, height/2); 
  text(nf((float)brightness[2]/2.55, 3, 1)+"%", width-width/6, height/2); 

  // WALL LIGHT
  if (lamps[0].on()) {
    noFill(); 
    stroke(brightness[0]); 
    strokeWeight(5); 
    pushMatrix(); 
    translate(width/6, height/2); 
    rotate(HALF_PI); 
    arc(0, 0, .9*TRAJECTORY_SIZE*2, .9*TRAJECTORY_SIZE*2, ((float)(lightPARAM[0]/(float)LEDstrips[0].length)*PI), TWO_PI-((float)(lightPARAM[0]/(float)LEDstrips[0].length*PI))); 
    popMatrix();
  }

  // STANDING LIGHT 
  if (lamps[1].on()) {
    rectMode(CENTER); 
    noFill(); 
    stroke(brightness[1]); 
    strokeWeight(5); 
    pushMatrix(); 
    translate(width/2, height/2); 

    beginShape(); // [1] standmode : 0 = all lights on, 1 = top lights on, 2 = bottom lights on, 3 = off; 
    if (lightPARAM[1] == 0 || lightPARAM[1] == 1) {
      vertex(-.9*TRAJECTORY_SIZE, 0); 
      vertex(0, .9*TRAJECTORY_SIZE); 
      vertex(.9*TRAJECTORY_SIZE, 0);
    }
    if (lightPARAM[1] == 2) vertex(.9*TRAJECTORY_SIZE, 0); 
    if (lightPARAM[1] == 0 || lightPARAM[1] == 2) {
      vertex(0, -.9*TRAJECTORY_SIZE); 
      vertex(-.9*TRAJECTORY_SIZE, 0);
    }
    endShape(); 
    popMatrix();
  }

  // CEILING LIGHT
  if (lamps[2].on()) {
    noFill(); 
    strokeWeight(5); 
    pushMatrix(); 
    translate(width-width/6, height/2); 
    line(-50, 0, 50, 0);
    stroke(abs(constrain(lightPARAM[2], -75, 0)*3), 100, abs(constrain(lightPARAM[2], 0, 75))*3);
    line(0, 0, lightPARAM[2], 0);
    rotate(HALF_PI); 
    stroke(brightness[2]); 
    ellipse(0, 0, .9*TRAJECTORY_SIZE*2, .9*TRAJECTORY_SIZE*2); 
    popMatrix();
  }
}

public void dispose()
{
  println("Closing Watch Thread..."); 
  udpWATCH_running = false; 
  udp_esp.close(); 
  delay(500); // so whe can still print the messages from the other thread(s) for debugging
}

public class button {
  boolean on_off;
  color background_off = color(5, 40, 20);
  color background_on = color(50, 30, 30);
  String text;
  float[] size, position;

  public button(String _text, float _position_x, float _position_y, float _size_x, float _size_y, boolean status) {
    text = _text;
    float[] temp = {_position_x-_size_x/2, _position_y};
    position = temp;
    float[] temp2 = {_size_x, _size_y};
    size = temp2;
    on_off = status;
  }

  public void draw() {
    rectMode(CORNER);
    noStroke();
    if (on_off)
      fill(background_off);
    else 
    fill (background_on);

    rect(position[0], position[1], size[0], size[1]);
    textAlign(CENTER);
    fill(255);
    textSize(size[1]/3);
    text(text, position[0]+size[0]/2, position[1]+size[1]/2);
  }

  public boolean on() {
    return on_off;
  }

  public boolean toggled(float _x, float _y) {
    if (_x>position[0] && _x<position[0]+size[0] && _y>position[1] && _y<position[1]+size[1]) {
      on_off = !on_off;
      return true;   // mouseclick was in button
    }
    return false;    // mouseclick was not in button
  }
}

void mousePressed() {
  viewStat.toggled(mouseX, mouseY);
  viewTargets.toggled(mouseX, mouseY);
  simulationButton.toggled(mouseX, mouseY);
  simulation = simulationButton.on();       
  for (int i = 0; i< lamps.length; i++)
    if (lamps[i].toggled(mouseX, mouseY))
      lampToggle = true;
}