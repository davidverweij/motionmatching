public class Trial
{
  public ArrayList<Target> targets;          // all the dials contained in this trial
  private int[] speed;
  private String[] size;
  private color[] c_olor;
  private int amount;
  private String[] x_positions;
  private String[] y_positions;
  private int[] directions;
  private float[] degrees;


  // create a trial
  public Trial(String[] _x_positions, String[] _y_positions, int[] _directions, float[] _degrees, int[] _speed, String[] _size, color[] _c_olor)      
  {
    targets = new ArrayList<Target>();
    x_positions = _x_positions;
    y_positions = _y_positions;
    directions = _directions;
    c_olor = _c_olor;
    degrees = _degrees;
    speed = _speed;
    size = _size;
    amount = _x_positions.length;        // must be an even number
  
    for (int i = 0; i < amount; i++) {
      targets.add(new Target(size[i], TARGET_SIZE, speed[i], degrees[i], directions[i], x_positions[i], y_positions[i], c_olor[i]));
    }
  }

  public String[] getSize()
  {
    return this.size;
  }

  public int[] getSpeed()
  {
    return this.speed;
  }

  public int getAmount()
  {
    return amount;
  }

  public void draw()
  {    
    for(int i = amount-1; i >= 0; i--) {      // makes sure the red target is drawn last (no black line through target)
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