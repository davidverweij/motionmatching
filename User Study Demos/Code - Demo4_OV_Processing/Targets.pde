void makeTrialPackage()
{
  trialPackage = new ArrayList<Trial>();

  float xT = column[2]+(.25*(column[3]-column[2]));
  float sT = trainRow*.8;

  /* Size trajectory  --> */  float[]   s_0 = {sT,sT,sT,sT,sT,sT,sT};
  /* border trajectory -->*/  float[]   b_0 = {2f, 2f, 2f, 2f, 2f, 2f, 2f};
  /* color trajectory -->*/  color[]   cT_0 = {WTlight, color(255),WTlight, color(255),WTlight, color(255),WTlight};
  /* Color Target     --> */  color[] c_0 =  {WT, WT, WT, WT, WT, WT, WT};
  /* X position       --> */  float[] x_0 = {xT, xT, xT, xT, xT, xT, xT}; 
  /* Y position       --> */  float[] y_0 = {0, 0, 0, 0, 0, 0, 0};
  for (int i = 0; i<7; i++)
    y_0[i] = border+trainRow*(i+1);
  /* Direction        --> */  int[]   d_0 = {1, -1, 1, -1, 1, -1, 1};
  /* Starting Angle   --> */  float[] g_0 = {0, 0, 90, 90, 180, 180, 270};
  /* Speed Orbit      --> */  int[]   sp_0 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_0, y_0, d_0, g_0, sp_0, s_0, b_0, c_0, cT_0));
}

public class Trial
{
  public ArrayList<Target> targets;          // all the dials contained in this trial
  private int[] speed;
  private float[] size;
  private color[] c_olor, cT_olor;
  private int amount;
  private float[] x_positions;
  private float[] y_positions;
  private int[] directions;
  private float[] degrees;
  private float[] border;

  // create a trial
  public Trial(float[] _x_positions, float[] _y_positions, int[] _directions, float[] _degrees, int[] _speed, float[] _size, float[] _border, color[] _c_olor, color[] _cT_olor)      
  {
    targets = new ArrayList<Target>();
    x_positions = _x_positions;
    y_positions = _y_positions;
    directions = _directions;
    c_olor = _c_olor;
    cT_olor = _cT_olor;
    degrees = _degrees;
    speed = _speed;
    size = _size;
    border = _border;
    amount = _x_positions.length;        // must be an even number

    for (int i = 0; i < amount; i++) {
      targets.add(new Target(size[i], border[i], TARGET_SIZE, speed[i], degrees[i], directions[i], x_positions[i], y_positions[i], c_olor[i], cT_olor[i]));
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
  private color c, cT;

  // size , speed , startangle , direction (1 = CW, -1 = CCW)
  public Target(float _size, float _trajBorder, float _t_size, int _speed, float _startAngle, int _direction, float _x, float _y, color _c, color _cT)
  {
    x = _x;
    y = _y;
    size = _size;
    t_size = _t_size;
    direction = _direction;
    speed = _speed*_direction;
    initialAngle = _startAngle;
    c = _c;
    cT = _cT;
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
      stroke(cT);
    }
    ellipseMode(CENTER);
    ellipse(x, y, radius*2, radius*2);

    // the target
    fill(c);
    stroke(20);
    strokeWeight((int)border);
    ellipse(tx, ty, t_size, t_size);
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
}