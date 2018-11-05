void makeTrialPackage()
{
  trialPackage = new ArrayList<Trial>();

  // ALL ARRAYS NEED the same amount of TARGETS (NOW ----- 6 ----)

  /* Size trajectory  --> */  float[]   s_0 = {2*userSize, 2*userSize, 2*userSize, 500, 500, 500};
  /* border trajectory -->*/  float[]   b_0 = {0f, 0f, 0f, 0f, 0f, 0f};
  /* Color Target     --> */  color[] c_0 =  {color(0, 161, 131, 150), color(0, 161, 131, 150), color(0, 161, 131, 150), color(0), color(0), color(0)};
  /* X position       --> */  float[] x_0 = {CENTERX, CENTERX, CENTERX, 10*CENTERX, 10*CENTERX, 10*CENTERX}; 
  /* Y position       --> */  float[] y_0 = {CENTERY, CENTERY, CENTERY, 10*CENTERY, 10*CENTERY, 10*CENTERY};
  /* Direction        --> */  int[]   d_0 = {1, 1, 1, -1, -1, -1};
  /* Starting Angle   --> */  float[] g_0 = {0, 120, 240, 180, 180, 180};
  /* Speed Orbit      --> */  int[]   sp_0 = {LOW_SPEED, LOW_SPEED, LOW_SPEED, LOW_SPEED, LOW_SPEED, LOW_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_0, y_0, d_0, g_0, sp_0, s_0, b_0, c_0));

  /* Size trajectory -->  */  float[]   s_1 = {userSize-7, userSize-7, userSize-7, userSize-7, 500, 500};
  /* border trajectory -->*/  float[]   b_1 = {0f, 0f, 0f, 0f, 0, 0};
  /* Color Target    -->  */  color[] c_1 =  {color(255), color(255), color(255), color(255), color(0), color(0)};
  /* X position      -->  */  float[] x_1 = {posUser1, posUser2, posUser3, posUser4, 10*CENTERX, 10*CENTERX}; 
  /* Y position      -->  */  float[] y_1 = {height/2, height/2, height/2, height/2, 10*CENTERY, 10*CENTERY};
  /* Direction       -->  */  int[]   d_1 = {1, 1, 1, 1, -1, -1};
  /* Starting Angle  -->  */  float[] g_1 = {0, 90, 180, 270, 0, 0};
  /* Speed Orbit      --> */  int[]   sp_1 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_1, y_1, d_1, g_1, sp_1, s_1, b_1, c_1));

  /* Size trajectory -->  */  float[]   s_2 = {sizeScroll, sizeScroll, sizeUp, sizeDown, sizePlay, sizeExit};
  /* border trajectory -->*/  float[]   b_2 = {0f, 0f, height/45, height/45, height/45, height/45};
  /* Color Target    -->  */  color[] c_2 =  {color(0, 161, 131), color(0, 161, 131), color(255), color(255), color(255), color(255, 0, 0)};
  /* X position      -->  */  float[] x_2 = {CENTERX, CENTERX, CENTERX, CENTERX, distLeft+sizePlay/2, width-posExit}; 
  /* Y position      -->  */  float[] y_2 = {posScroll, posScroll, posUp, posDown, posPlay, posExit};
  /* Direction       -->  */  int[]   d_2 = {1, -1, 1, -1, 1, -1};
  /* Starting Angle  -->  */  float[] g_2 = {0, 0, 120, 120, 240, 240};
  /* Speed Orbit      --> */  int[]   sp_2 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_2, y_2, d_2, g_2, sp_2, s_2, b_2, c_2));

  /* Size trajectory -->  */  float[]   s_3 = {sizeScroll2, sizeScroll2, sizeVol, sizeVol, sizePlay, sizeExit};
  /* border trajectory -->*/  float[]   b_3 = {0f, 0f, 0f, 0f, 0f, 0f};
  /* Color Target    -->  */  color[] c_3 =  {color(0, 161, 131), color(0, 161, 131), color(255), color(255), color(255), color(255, 0, 0)};
  /* X position      -->  */  float[] x_3 = {CENTERX, CENTERX, posVol, posVol, posPlay2, width-posExit}; 
  /* Y position      -->  */  float[] y_3 = {posMenu, posMenu, posMenu, posMenu, posMenu, posExit};
  /* Direction       -->  */  int[]   d_3 = {1, -1, 1, -1, 1, -1};
  /* Starting Angle  -->  */  float[] g_3 = {0, 0, 120, 120, 240, 240};
  /* Speed Orbit      --> */  int[]   sp_3 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  trialPackage.add(new Trial(x_3, y_3, d_3, g_3, sp_3, s_3, b_3, c_3));
  trialPackage.get(3).targets.get(5).setExitSTATE3();
}

public class Trial
{
  public ArrayList<Target> targets;          // all the dials contained in this trial
  private int[] speed;
  private float[] size;
  private color[] c_olor;
  private int amount;
  private float[] x_positions;
  private float[] y_positions;
  private int[] directions;
  private float[] degrees;
  private float[] border;

  // create a trial
  public Trial(float[] _x_positions, float[] _y_positions, int[] _directions, float[] _degrees, int[] _speed, float[] _size, float[] _border, color[] _c_olor)      
  {
    targets = new ArrayList<Target>();
    x_positions = _x_positions;
    y_positions = _y_positions;
    directions = _directions;
    c_olor = _c_olor;
    degrees = _degrees;
    speed = _speed;
    size = _size;
    border = _border;
    amount = _x_positions.length;        // must be an even number

    for (int i = 0; i < amount; i++) {
      targets.add(new Target(size[i], border[i], TARGET_SIZE, speed[i], degrees[i], directions[i], x_positions[i], y_positions[i], c_olor[i]));
    }
  }

  public float[] getSize()
  {
    return this.size;
  }

  public int[] getSpeed()
  {
    return this.speed;
  }

  public int getAmount() {   
    return amount;
  }

  public void draw()
  {    
    for (int i = amount-1; i >= 0; i--) {      // makes sure the red target is drawn last (no black line through target)
      targets.get(i).draw();
    }
  }

  public void updatePos(long currentTime)
  { 
    for (int i = 0; i < amount; i++) {
      targets.get(i).updateTargetPos(currentTime);
    }
  }

  public float[][] getTargetPos(long timestamp) {
    float[][] x_y = new float[amount][2];
    for (int i = 0; i < amount; i++) {
      x_y[i] = targets.get(i).getTargetPos(timestamp);
    }
    return x_y;
  }
}

public class Target
{
  private float angle;
  private float initialAngle;
  private float t_size, size;
  private float radius;
  private int speed;
  private int direction;
  private float string_x, string_y;
  private int border;
  private float trajBorder;
  private float x, y, tx, ty;
  private color c;
  private boolean exitSTATE3 = false;

  // size , speed , startangle , direction (1 = CW, -1 = CCW)
  public Target(float _size, float _trajBorder, float _t_size, int _speed, float _startAngle, int _direction, float _x, float _y, color _c)
  {
    x = _x;
    y = _y;
    size = _size;
    t_size = _t_size;
    direction = _direction;
    speed = _speed*_direction;
    initialAngle = _startAngle;
    c = _c;
    border = 0;
    trajBorder = _trajBorder;
    radius = size/2;

    tx = x + cos(radians(angle)) * radius;
    ty = y + sin(radians(angle)) * radius;
  }

  public void draw()
  { 
    // the big circle
    noFill();
    if (trajBorder == 0) noStroke();
    else {
      stroke(100);
      strokeWeight(trajBorder);
    }
    if (exitSTATE3) ellipse(x, y-menuToggleCounter*1.3333333, radius*2, radius*2);
    else ellipse(x, y, radius*2, radius*2);

    // the target
    fill(c);
    stroke(0);
    strokeWeight((int)border);
    if (exitSTATE3) ellipse(tx, ty-menuToggleCounter*1.3333333, t_size, t_size);
    else ellipse(tx, ty, t_size, t_size);
    noStroke();
  }

  public void updateTargetPos(long targetTime)
  {
    angle = (float)((float)(targetTime-trialStarted)*(speed))/1000;
    tx = x + cos(radians(initialAngle+angle)) * radius;
    ty = y + sin(radians(initialAngle+angle)) * radius;
  }

  public float[] getTargetPos(long timestamp) {
    float _x, _y;
    float _angle = (float)((float)(timestamp-trialStarted)*(speed))/1000;
    _x = x + cos(radians(initialAngle+_angle)) * radius;
    _y = y + sin(radians(initialAngle+_angle)) * radius;

    float[] x_y = {_x, _y};
    return x_y;
  }

  public void targetSelected(int _border)
  {
    border = _border;
  }

  public void setColor(color _c)
  {
    c = _c;
  }

  public void setSize(float _t_size) {
    t_size = _t_size;
  }
  
  public void setExitSTATE3 (){
    exitSTATE3 = true;
  }
}