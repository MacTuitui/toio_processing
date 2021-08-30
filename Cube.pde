class Cube {
  int x;
  int y;
  int prex;
  int prey;
  int oidx;
  int oidy;
  float targetx =-1;
  float targety =-1;  
  boolean isLost;
  int id;
  int deg;
  long lastUpdate;
  int count=0;

  Cube(int i, boolean lost) {
    id = i;
    isLost=lost;

    lastUpdate = System.currentTimeMillis();
  }
  void resetCount() {
    count =0;
  }

  boolean isAlive(long now) {
    return(now < lastUpdate+200);
  }

  int[] aimslow(float tx, float ty) {
    int left = 0;
    int right = 0;
    float angleToTarget = atan2(ty-y, tx-x);
    float thisAngle = deg*PI/180;
    float diffAngle = thisAngle-angleToTarget;
    if (diffAngle > PI) diffAngle -= TWO_PI;
    if (diffAngle < -PI) diffAngle += TWO_PI;
    //if in front, go forward and
    if (abs(diffAngle) < HALF_PI) {
      //in front
      float frac = cos(diffAngle);
      //println(frac);
      if (diffAngle > 0) {
        //up-left
        left = floor(100*pow(frac, 1));
        right = 100;
      } else {
        left = 100;
        right = floor(100*pow(frac, 1));
      }
    } else {
      //face back
      if (diffAngle > 0) {
        left  = -30;
        right =  30;
      } else {
        left  =  30;
        right = -30;
      }
    }

    int[] res = new int[2];
    res[0]= left;
    res[1] = right;
    return res;
  }


  //This function defines how the cubes aims at something
  //the perceived behavior will strongly depend on this
  int[] aim(float tx, float ty) {
    int left = 0;
    int right = 0;
    float angleToTarget = atan2(ty-y, tx-x);
    float thisAngle = deg*PI/180;
    float diffAngle = thisAngle-angleToTarget;
    if (diffAngle > PI) diffAngle -= TWO_PI;
    if (diffAngle < -PI) diffAngle += TWO_PI;
    //if in front, go forward and
    if (abs(diffAngle) < HALF_PI) {
      //in front
      float frac = cos(diffAngle);
      if (diffAngle > 0) {
        //up-left
        left = floor(100*pow(frac, 2));
        right = 100;
      } else {
        left = 100;
        right = floor(100*pow(frac, 2));
      }
    } else {
      //face back
      float frac = -cos(diffAngle);
      if (diffAngle > 0) {
        left  = -floor(100*frac);
        right =  -100;
      } else {
        left  =  -100;
        right = -floor(100*frac);
      }
    }

    int[] res = new int[2];
    res[0] = left;
    res[1] = right;
    return res;
  }
  float distance(Cube o) {
    return distance(o.x, o.y);
  }

  float distance(float ox, float oy) {
    return sqrt ( (x-ox)*(x-ox) + (y-oy)*(y-oy));
  }
}
