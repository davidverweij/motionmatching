ArrayList<ArrayList<TargetMode>> Lights = null;    // Targets (class)

final static float TRAJECTORY_SIZE = 100;

void makeTargets() {

  Lights = new ArrayList<ArrayList<TargetMode>>(numLEDstrips);
  for (int i = 0; i<numLEDstrips; i++)
    Lights.add(new ArrayList<TargetMode>());


  int speed = 120;        // target speed
  color selection = color(0,150,255);      // initial selection color


  /*
   *       WALL LIGHT 
   */
  if (numLEDstrips>=1) {
    //MODE 0 --> IDLE / SELECT MODE
    int[] dir00 = {1};  // 1 clockwise | -1 counter_clock
    float[] degr00 = {0};  // phase              // check with other lights. None the same!! (e.g. 120 degrees different)
    int[] speed00 = {speed};  // degrees/s
    color[] colour00 = {selection};
    Lights.get(0).add(new TargetMode(0, (float)width/6, dir00, degr00, speed00, colour00));      //'0' is for Cirlc. '1' is for Rhomboid

    //MODE 2 --> Select Beam direction
    int[] dir01 = {1, -1};  // 1 clockwise | -1 counter_clock
    float[] degr01 = {180, 180};  // phase
    int[] speed01 = {speed, speed};  // degrees/s
    color[] colour01 = {color(34, 255, 150), color(255, 100, 50)};
    Lights.get(0).add(new TargetMode(0, (float)width/6, dir01, degr01, speed01, colour01));
  }


  /*
   *       STANDING LIGHT
   */
  if (numLEDstrips>=2) {
    //MODE 0 --> IDLE / SELECT MODE
    int[] dir10 = {1};  // 1 clockwise | -1 counter_clock
    float[] degr10 = {120};  // phase
    int[] speed10 = {speed};  // degrees/s
    color[] colour10 = {selection};
    Lights.get(1).add(new TargetMode(1, (float)width/2, dir10, degr10, speed10, colour10));  


    //MODE 2 --> Select Beam direction          // all on, top, bottom
    int[] dir11 = {1, 2, 3};  // 1 clockwise | -1 counter_clock      // 2 == back and forth top, 3 == back and forth bottom
    float[] degr11 = {0, 270, 90};  // phase
    int[] speed11 = {speed, speed, speed};  // degrees/s
    color[] colour11 = {color(150, 0, 201), color(56, 156, 186), color(179, 125, 245)};
    Lights.get(1).add(new TargetMode(1, (float)width/2, dir11, degr11, speed11, colour11));
  }
  /*
   *       CEILING LIGHTS 
   */
  if (numLEDstrips>=3) {
    //MODE 0 --> IDLE / SELECT MODE
    int[] dir20 = {1};  // 1 clockwise | -1 counter_clock
    float[] degr20 = {240};  // phase
    int[] speed20 = {speed};  // degrees/s
    color[] colour20 = {selection};
    Lights.get(2).add(new TargetMode(0, (float)width/6*5, dir20, degr20, speed20, colour20));  

    //MODE 2 --> Select Beam direction
    int[] dir21 = {1, -1};  // 1 clockwise | -1 counter_clock
    float[] degr21 = {0, 180};  // phase
    int[] speed21 = {speed, speed};  // degrees/s
    color[] colour21 = {color(100, 100, 255),color(255, 50, 0)};
    Lights.get(2).add(new TargetMode(0, (float)width/6*5, dir21, degr21, speed21, colour21));
  }
}

public class TargetMode {

  public ArrayList<Target> targets;          // all the dials contained in this trial
  private int[] speed;
  private int[] directions;
  private float[] degrees;
  private color[] colour;
  private float x_pos;

  public TargetMode(int shape, float _x_pos, int[] _directions, float[] _degrees, int[] _speed, color[] _colour) {
    targets = new ArrayList<Target>();
    x_pos = _x_pos;
    directions = _directions;
    degrees = _degrees;
    speed = _speed;
    colour = _colour;

    for (int i = 0; i < directions.length; i++) 
      targets.add(new Target(shape, x_pos, speed[i], degrees[i], directions[i], colour[i]));
  }

  public void draw(long now) {
    targets.get(0).drawT();            // draw trajectory 
    for (int i = 0; i < targets.size(); i++) {  // draw targets
      targets.get(i).draw(now);
    }
  }
}


public class Target
{
  private float angle;
  private int shape;
  private float initialAngle;
  private int speed;
  private int direction;
  private int back_forth = 0;
  private float tx, ty;
  private color colour;
  private color original;
  private float x_pos;
  private float sides;

  // size , speed , startangle , direction (1 = CW, -1 = CCW)
  public Target(int _shape, float _x_pos, int _speed, float _startAngle, int _direction, color _colour)
  {
    shape = _shape;
    x_pos = _x_pos;
    if (_direction > 1) {    // if back and forth target
      direction = 1; 
      back_forth = _direction;
    } else 
    direction = _direction;

    speed = _speed*direction;
    initialAngle = _startAngle;   
    colour = _colour;
    original = colour;
    if (shape == 1)
      sides = sqrt(2)*TRAJECTORY_SIZE;
  }

  public color getColor() {
    return colour;
  }

  public void setColor(int q) {
    if (q == 0) 
      colour = color(0);
    else 
    colour = original;
  }


  public float[] getTargetPos(long timestamp) {    
    angle = ((float)((float)(timestamp)*(speed))/1000);
    //println(speed);
    float current_angle = (initialAngle+angle)%360;
    if (shape == 0) {
      tx = x_pos + cos(radians(current_angle)) * TRAJECTORY_SIZE;
      ty = height/2 + sin(radians(current_angle)) * TRAJECTORY_SIZE;
    } else {
      // wrap the pos to the progress in degrees
      if (current_angle<=180) // bottom part
        tx = x_pos - (current_angle-90)*(TRAJECTORY_SIZE/90);
      else 
      tx = x_pos + (current_angle-270)*(TRAJECTORY_SIZE/90);

      switch(back_forth) {
      case 2:
        if (current_angle>180) current_angle = 180-current_angle%180;
        break;
      case 3:
      if (current_angle<180) current_angle = 360-current_angle;
        break;
      }

      if (current_angle>=90 && current_angle <=270)
        ty = height/2 - ((current_angle+270)%360-90)*(TRAJECTORY_SIZE/90);
      else 
      ty = height/2 + ((current_angle+270)%360-270)*(TRAJECTORY_SIZE/90);
    }

    float[] angle_x_y = {current_angle, tx, ty};
    return angle_x_y;
  }

  public void drawT() {
    stroke(100);
    strokeWeight(height/200);
    noFill();
    if (shape==0)

      ellipse(x_pos, height/2, 2*TRAJECTORY_SIZE, 2*TRAJECTORY_SIZE);
    else {
      beginShape();
      vertex(x_pos, height/2-TRAJECTORY_SIZE);
      vertex(x_pos-TRAJECTORY_SIZE, height/2);
      vertex(x_pos, height/2+TRAJECTORY_SIZE);
      vertex(x_pos+TRAJECTORY_SIZE, height/2);
      endShape(CLOSE);
    }
  }

  public void draw(long now) {
    float[] _angle_x_y = this.getTargetPos(now);
    noStroke();
    fill(colour);
    if (colour!=color(0))ellipse(_angle_x_y[1], _angle_x_y[2], 20, 20);
  }
}