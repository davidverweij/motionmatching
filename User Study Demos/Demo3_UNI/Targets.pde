void makeTrialPackage()
{
  trialPackage = new ArrayList<Trial>();
  trialPackageAdd = new ArrayList<Trial>();
  
 /* Size trajectory  --> */  float[]   s_00 = {100};
  /* border trajectory -->*/  float[]   b_00 = {0f};
  /* color trajectory -->*/  color[]   cT_00 = {color(255)};
  /* Color Target     --> */  color[] c_00 =  {WT};
  /* Size Target     --> */  float[] cs_00 =  {0};
  /* X position       --> */  float[] x_00 = {-width}; 
  /* Y position       --> */  float[] y_00 = {-height};
  /* Direction        --> */  int[]   d_00 = {1};
  /* Starting Angle   --> */  float[] g_00 = {0};
  /* Speed Orbit      --> */  int[]   sp_00 = {5*HIGH_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_00, y_00, d_00, g_00, sp_00, s_00, b_00, c_00, cs_00, cT_00));

  /* Size trajectory  --> */  float[]   s_0 = {Q1_targetSize, Q1_targetSize, Q1_targetSize, Q1_targetSize, Q1_targetSize, Q1_targetSize};
  /* border trajectory -->*/  float[]   b_0 = {0f, 0f, 0f, 0f, 0f, 0f};
  /* color trajectory -->*/  color[]   cT_0 = {color(255), color(255), color(255), color(255), color(255), color(255)};
  /* Color Target     --> */  color[] c_0 =  {WT, WT, WT, WT, WT, WT, WT};
  /* Size Target     --> */  float[] cs_0 =  {TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE};
  /* X position       --> */  float[] x_0 = {Q1_topLeftX, Q1_topLeftX, Q1_topLeftX, Q1_topLeftX, Q1_topLeftX, Q1_topLeftX}; 
  /* Y position       --> */  float[] y_0 = {Q1_topLeftY, Q1_topLeftY+1*Q1_targetDist, Q1_topLeftY+2*Q1_targetDist, Q1_topLeftY+3*Q1_targetDist, Q1_topLeftY+4*Q1_targetDist, Q1_topLeftY+5*Q1_targetDist};
  /* Direction        --> */  int[]   d_0 = {1, -1, 1, -1, 1, -1, 1};
  /* Starting Angle   --> */  float[] g_0 = {0, 0, 120, 120, 240, 240};
  /* Speed Orbit      --> */  int[]   sp_0 = {MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED, MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_0, y_0, d_0, g_0, sp_0, s_0, b_0, c_0, cs_0, cT_0));

  /* Size trajectory  --> */  float[]   s_1 = {Q2_targetSize,Q2_targetSize};
  /* border trajectory -->*/  float[]   b_1 = {0f, 0f, 0f, 0f, 0f, 0f};
  /* color trajectory -->*/   color[]   cT_1 = {color(255), color(255), color(255), color(255), color(255), color(255)};
  /* Color Target     --> */  color[] c_1 =  {WT, WTred};
    /* Size Target     --> */  float[] cs_1 =  {TARGET_SIZE*2,TARGET_SIZE*2};
  /* X position       --> */  float[] x_1 = {Q1_topLeftX+Q1R_L/2, Q1_topLeftX+Q1R_L/2}; 
  /* Y position       --> */  float[] y_1 = {Q2_targetY,Q2_targetY};
  /* Direction        --> */  int[]   d_1 = {1, -1};
  /* Starting Angle   --> */  float[] g_1 = {0, 0};
  /* Speed Orbit      --> */  int[]   sp_1 = {MED_SPEED, MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_1, y_1, d_1, g_1, sp_1, s_1, b_1, c_1, cs_1, cT_1));
  
   /* Size trajectory  --> */  float[]   s_2 = {Q3_targetSize,Q3_targetSize,Q3_targetSize,Q3_targetSize};
  /* border trajectory -->*/  float[]   b_2 = {0f, 0f, 0f, 0f};
  /* color trajectory -->*/   color[]   cT_2 = {color(255), color(255), color(255), color(255)};
  /* Color Target     --> */  color[] c_2 =  {color(0,189,255),color(0,189,255),color(0,189,255),color(0,189,255)};      //blue
    /* Size Target     --> */  float[] cs_2 =  {TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE};
  /* X position       --> */  float[] x_2 = {Q1_topLeftX+0*Q1R_L/3,Q1_topLeftX+1*Q1R_L/3,Q1_topLeftX+2*Q1R_L/3,Q1_topLeftX+3*Q1R_L/3}; 
  /* Y position       --> */  float[] y_2 = {Q3_targetY,Q3_targetY,Q3_targetY,Q3_targetY};
  /* Direction        --> */  int[]   d_2 = {1, 1,1,1};
  /* Starting Angle   --> */  float[] g_2 = {0, 90,180,270};
  /* Speed Orbit      --> */  int[]   sp_2 = {MED_SPEED, MED_SPEED,MED_SPEED,MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_2, y_2, d_2, g_2, sp_2, s_2, b_2, c_2, cs_2, cT_2));
  
  c_2 = new color[]{color(29,211,0),color(29,211,0),color(29,211,0),color(29,211,0)};    //green
  g_2 = new float[]{90,180,270,0};
  /*  ADD TO ARRAYLIST    */  trialPackageAdd.add(new Trial(x_2, y_2, d_2, g_2, sp_2, s_2, b_2, c_2, cs_2, cT_2));
  c_2 = new color[]{color(155,0,237),color(155,0,237),color(155,0,237),color(155,0,237)}; // purple
  g_2 = new float[]{180,270,0,90};
  /*  ADD TO ARRAYLIST    */  trialPackageAdd.add(new Trial(x_2, y_2, d_2, g_2, sp_2, s_2, b_2, c_2, cs_2, cT_2));
  c_2 = new color[]{color(255,206,0),color(255,206,0),color(255,206,0),color(255,206,0)};  //yellow
  g_2 = new float[]{270,0,90,180};
  /*  ADD TO ARRAYLIST    */  trialPackageAdd.add(new Trial(x_2, y_2, d_2, g_2, sp_2, s_2, b_2, c_2, cs_2, cT_2));
  
  
   /* Size trajectory  --> */  float[]   s_3 = {Q1_targetDist,Q1_targetDist,Q1_targetDist,Q1_targetDist,Q1_targetDist};
  /* border trajectory -->*/  float[]   b_3 = {0f, 0f, 0f, 0f, 0f};
  /* color trajectory -->*/   color[]   cT_3 = {color(255), color(255), color(255), color(255),color(255)};
  /* Color Target     --> */  color[] c_3 =  {WT,WT,WT,WT,WT};
    /* Size Target     --> */  float[] cs_3 =  {TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE,TARGET_SIZE};
  /* X position       --> */  float[] x_3 = {Q1_topLeftX+0*Q1R_L/4,Q1_topLeftX+1*Q1R_L/4,Q1_topLeftX+2*Q1R_L/4,Q1_topLeftX+3*Q1R_L/4,Q1_topLeftX+4*Q1R_L/4}; 
  /* Y position       --> */  float[] y_3 = {Q3_targetY,Q3_targetY,Q3_targetY,Q3_targetY,Q3_targetY};
  /* Direction        --> */  int[]   d_3 = {-1, -1,1,1,1};
  /* Starting Angle   --> */  float[] g_3 = {270, 180,0,180,270};
  /* Speed Orbit      --> */  int[]   sp_3 = {MED_SPEED, MED_SPEED,MED_SPEED,MED_SPEED,MED_SPEED};              // speeds

  /*  ADD TO ARRAYLIST    */  trialPackage.add(new Trial(x_3, y_3, d_3, g_3, sp_3, s_3, b_3, c_3, cs_3, cT_3));
  
 //for (int i = 0; i<5; i++) {
    //  ellipse(Q1_topLeftX+i*Q1R_L/4, Q3_targetY, Q1_targetDist, Q1_targetDist);
    //}
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
  private float[] cs_target;

  // create a trial
  public Trial(float[] _x_positions, float[] _y_positions, int[] _directions, float[] _degrees, int[] _speed, float[] _size, float[] _border, color[] _c_olor, float[] _cs_target, color[] _cT_olor)      
  {
    targets = new ArrayList<Target>();
    x_positions = _x_positions;
    y_positions = _y_positions;
    directions = _directions;
    c_olor = _c_olor;
    cs_target = _cs_target;
    cT_olor = _cT_olor;
    degrees = _degrees;
    speed = _speed;
    size = _size;
    border = _border;
    amount = _x_positions.length;        // must be an even number

    for (int i = 0; i < amount; i++) {
      targets.add(new Target(size[i], border[i], cs_target[i], speed[i], degrees[i], directions[i], x_positions[i], y_positions[i], c_olor[i], cT_olor[i]));
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