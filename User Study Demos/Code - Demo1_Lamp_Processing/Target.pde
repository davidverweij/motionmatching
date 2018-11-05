public class Target
{
  private float angle;
  private float initialAngle;
  private float t_size;
  private float radius;
  private int speed;
  private int direction;
  private String size, string_x, string_y;
  private int border;
  private float x, y, tx, ty;
  private color c;

  // size , speed , startangle , direction (1 = CW, -1 = CCW)
  public Target(String _size, float _t_size, int _speed, float _startAngle, int _direction, String _x, String _y, color _c)
  {
    string_x = _x;
    string_y = _y;
    size = _size;
    t_size = _t_size;
    direction = _direction;
    speed = _speed*_direction;
    initialAngle = _startAngle;
    c = _c;
    border = 0;
    
    calcX(); calcRadius();

    tx = x + cos(radians(angle)) * radius;
    ty = y + sin(radians(angle)) * radius;
  }

  public void draw()
  { 
    calcX(); calcY(); calcRadius();
    
 /*   // the big circle
    noFill();
    stroke(100);
    strokeWeight(6);
    ellipse(x, y, radius*2, radius*2);
*/
    // the target
    fill(c);
    stroke(200);
    strokeWeight(border);
    ellipse(tx, ty, t_size, t_size);
    noStroke();
  }

  public void updateTargetPos(long targetTime)
  {
    calcX(); calcRadius();
    
    angle = (float)((float)(targetTime-trialStarted)*(speed))/1000;
    tx = x + cos(radians(initialAngle+angle)) * radius;
    ty = y + sin(radians(initialAngle+angle)) * radius;
  }

  public float[] getTargetPos(long timestamp) {
    calcX(); calcRadius();
    
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
  
  public void setSize(float _t_size){
   t_size = _t_size; 
  }

  public void calcX() {
    if (string_x.equals(xll)) x = CENTERX-SPACE*1.15*VDEGREE;
    else if (string_x.equals(xl)) x = CENTERX-SPACE*1*VDEGREE;
    else if (string_x.equals(xm)) x = CENTERX;
    else if (string_x.equals(xr)) x = CENTERX+SPACE*1*VDEGREE;
    else if (string_x.equals(xrr)) x = CENTERX+SPACE*1.15*VDEGREE;
  }
  
  public void calcY() {
    if (string_y.equals(yt)) y = CENTERY-SPACE*VDEGREE;
    else if (string_y.equals(ym)) y = CENTERY;
    else if (string_y.equals(yl)) y = CENTERY+SPACE*VDEGREE;
  }

  public void calcRadius() {
    if (size.equals(ss)) radius = SIZE_SMALL*VDEGREE / 2;
    else if (size.equals(sm)) radius = SIZE_MEDIUM*VDEGREE / 2;
    else if (size.equals(sb)) radius = SIZE_WIDE*0.57*VDEGREE;
  }
  
}