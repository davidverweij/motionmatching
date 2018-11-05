int NUM_OF_REPS   = 2;       // duplication of individual trial

void makeTrialPackage()
{
  // 2 4 8 12 16
  float d = VDEGREE*1.5/2;
  float dd = 6*d;
  float ddd = 12*d;
  float X = CENTERX;
  float Y = CENTERY;

  trialPackage = new ArrayList<Trial>();


  // ALL MEDIUM 4 TARGETS // CHECKED
  // on/off all, hue1, hue2, lessB1, moreB1 lessB2 moreB2
  /* String[]   s_1 = {ss,sm,sm,sm,sm,sm, sm};
   color[] c_1 = {color(0,255,0),color(255,0,255),color(255,0,255),color(155,155,0),color(255,255,0),color(155,155,0),color(255,255,0)};
   String[] x_1 = {xm,xl,xr,xl,xl,xr,xr}; 
   float[] y_1 = {Y, Y,Y, Y,Y, Y,Y};
   int[]   d_1 = {-1, 1,-1,-1,1,-1,1};
   float[] g_1 = {0,0,180,270,90,90,270};
   int[]   sp_1 ={MED_SPEED,MED_SPEED,MED_SPEED,MED_SPEED,MED_SPEED,MED_SPEED,MED_SPEED};              // speeds
   */

  /* Size trajectory --> */
  String[]   s_1 = {sb, sb, sb, sb, sb, sb};
  /* Color Target    --> */
  color[] c_1 =  {color(255, 0, 255), color(255, 255, 0), color(200, 200, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)};
  /* X position      --> */
  String[] x_1 = {xl, xl, xl, xr, xr, xr}; 
  /* Y position      --> */
  String[] y_1 = {ym, ym, ym, ym, ym, ym};
  /* Direction       --> */
  int[]   d_1 = {-1, 1, -1, 1, 1, 1};
  /* Starting Angle  --> */
  float[] g_1 = {180, 0, 0, 270, 180, 90};
  /* Speed Orbit      --> */
  int[]   sp_1 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  ///* Size trajectory --> */
  //String[]   s_1 = {sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb, sb};
  ///* Color Target    --> */
  //color[] c_1 =  {color(255, 0, 255), color(255, 255, 0), color(155, 155, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255),color(255, 0, 255), color(255, 255, 0), color(155, 155, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255),color(255, 0, 255), color(255, 255, 0), color(155, 155, 0), color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)};
  ///* X position      --> */
  //String[] x_1 = {xm, xm, xm, xm, xm, xm,xm, xm, xm, xm, xm, xm,xm, xm, xm, xm, xm, xm}; 
  ///* Y position      --> */
  //String[] y_1 = {yt, yt, yt, yl, yl, yl,yt, yt, yt, yl, yl, yl,yt, yt, yt, yl, yl, yl};
  ///* Direction       --> */
  //int[]   d_1 = {-1, 1, -1, 1, 1, 1,-1, 1, -1, 1, 1, 1,-1, 1, -1, 1, 1, 1};
  ///* Starting Angle  --> */
  //float[] g_1 = {180, 0, 0, 270, 180, 90,170, -10, -10, 260, 170, 80,190, 10, 10, 280, 190, 100};
  ///* Speed Orbit      --> */
  //int[]   sp_1 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED,MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED,MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  trialPackage.add(new Trial(x_1, y_1, d_1, g_1, sp_1, s_1, c_1));

  trialPackage.get(0).targets.get(3).setSize(0);
  trialPackage.get(0).targets.get(4).setSize(0);
  trialPackage.get(0).targets.get(5).setSize(0);
}




/*
void makeTrialPackage()
 {
 ArrayList<ArrayList<float[]>> positions = new ArrayList<ArrayList<float[]>>();
 ArrayList<float[]> one_positions = new ArrayList<float[]>();
 ArrayList<float[]> two_positions = new ArrayList<float[]>();
 ArrayList<float[]> three_positions = new ArrayList<float[]>();
 positions.add(one_positions);
 positions.add(two_positions);
 positions.add(three_positions);
 
 // 2 4 8 12 16
 float d = VDEGREE*1.5/2;
 float dd = 2*d;
 float ddd = 3*d;
 float X = CENTERX;
 float Y = CENTERY;
 
 float[] one_one     = {X-d, Y, X+d, Y};
 float[] one_two     = {X-d, Y-d, X-d, Y+d, X+d, Y-d, X+d, Y+d};  
 float[] one_three   = {X-3*d, Y-d, X-3*d, Y+d, X-d, Y-d, X-d, Y+d, X+d, Y-d, X+d, Y+d, X+3*d, Y-d, X+3*d, Y+d};
 float[] one_four    = {X-3*d, Y-1.5*d, X-3*d, Y, X-d, Y-1.5*d, X-d, Y, X+d, Y-1.5*d, X+d, Y, X+3*d, Y-1.5*d, X+3*d, Y, X-3*d, Y+1.5*d, X-d, Y+1.5*d, X+d, Y+1.5*d, X+3*d, Y+1.5*d};
 float[] one_five    = {X-3*d, Y-d, X-3*d, Y+d, X-d, Y-d, X-d, Y+d, X+d, Y-d, X+d, Y+d, X+3*d, Y-d, X+3*d, Y+d, X-3*d, Y-3*d, X-3*d, Y+3*d, X-d, Y-3*d, X-d, Y+3*d, X+d, Y-3*d, X+d, Y+3*d, X+3*d, Y-3*d, X+3*d, Y+3*d};
 
 positions.get(0).add(one_one);
 positions.get(0).add(one_two);
 positions.get(0).add(one_three);
 positions.get(0).add(one_four);
 positions.get(0).add(one_five);
 
 float[] two_one     = {X, Y, X, Y};
 float[] two_two     = {X-d, Y, X-d, Y,X+d, Y, X+d, Y};  
 float[] two_three   = {X-d, Y, X-d, Y,X+d, Y, X+d, Y, X-d, Y, X-d, Y,X+d, Y, X+d, Y};
 float[] two_four    = {X, Y, X, Y, X, Y, X, Y, X-d, Y, X-d, Y,X+d, Y, X+d, Y, X-d, Y, X-d, Y,X+d, Y, X+d, Y};
 float[] two_five    = {X-d, Y-d, X-d, Y-d,X+d, Y-d, X+d, Y-d, X-d, Y-d, X-d, Y-d,X+d, Y-d, X+d, Y-d,   X-d, Y+d, X-d, Y+d,X+d, Y+d, X+d, Y+d, X-d, Y+d, X-d, Y+d,X+d, Y+d, X+d, Y+d};
 
 positions.get(1).add(two_one);
 positions.get(1).add(two_two);
 positions.get(1).add(two_three);
 positions.get(1).add(two_four);
 positions.get(1).add(two_five);
 
 trialPackage = new ArrayList<Trial>();
 for (int q = 0; q < NUM_OF_REPS; q++) {  
 for (int size_i = 0; size_i < SIZE_ARR.length; size_i++) {
 for (int speed_i = 0; speed_i < SPEED_ARR.length; speed_i++) {
 for (int amount_i = 0; amount_i < AMOUNT_ARR.length; amount_i++) {
 trialPackage.add(new Trial(positions.get(size_i).get(amount_i), SPEED_ARR[speed_i], SIZE_ARR[size_i], AMOUNT_ARR[amount_i]));
 }
 }
 }
 }
 // mix up the trials
 Collections.shuffle(trialPackage, new Random(System.nanoTime()));
 }
 
 */