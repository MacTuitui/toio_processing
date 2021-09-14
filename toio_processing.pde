import oscP5.*;
import netP5.*;

//for OSC
OscP5 oscP5;
//where to send the commands to
NetAddress[] server;
int cubesPerHost = 4; // each BLE bridge can have up to 4 cubes

//we'll keep the cubes here
Cube[] cubes;
int nCubes =  4;

boolean mouseDrive = false;
boolean chase = false;
boolean spin = false;

void settings() {
  size(500, 500);
}


void setup() {
  // for OSC
  // receive messages on port 3333
  oscP5 = new OscP5(this, 3333);

  //send back to the BLE interface
  //we can actually have multiple BLE bridges
  server = new NetAddress[1]; //only one for now
  //send on port 3334 
  server[0] = new NetAddress("127.0.0.1", 3334);
  //server[1] = new NetAddress("192.168.0.103", 3334);
  //server[2] = new NetAddress("192.168.200.12", 3334);


  //create cubes
  cubes = new Cube[nCubes];
  for (int i = 0; i< cubes.length; ++i) {
    cubes[i] = new Cube(i, true);
  }

  //do not send TOO MANY PACKETS
  //we'll be updating the cubes every frame, so don't try to go too high
  frameRate(30);
}

void draw() {
  background(255);
  stroke(0);
  long now = System.currentTimeMillis();

  //draw the "mat"
  fill(255);
  rect(45, 45, 415, 410);

  //draw the cubes
  for (int i = 0; i < cubes.length; ++i) {
    if (cubes[i].isLost==false) {
      pushMatrix();
      translate(cubes[i].x, cubes[i].y);
      rotate(cubes[i].deg * PI/180);
      rect(-10, -10, 20, 20);
      rect(0, -5, 20, 10);
      popMatrix();
    }
  }

  if (chase) {
    cubes[0].targetx = cubes[0].x;
    cubes[0].targety = cubes[0].y;
    cubes[1].targetx = cubes[0].x;
    cubes[1].targety = cubes[0].y;
  } 
  //makes a circle with n cubes
  if (mouseDrive) {
    float mx = (mouseX);
    float my = (mouseY);
    float cx = 45+410/2;
    float cy = 45+410/2;

    float mulr = 180.0;

    float aMouse = atan2( my-cy, mx-cx);
    float r = sqrt ( (mx - cx)*(mx-cx) + (my-cy)*(my-cy));
    r = min(mulr, r);
    for (int i = 0; i< nCubes; ++i) {
      if (cubes[i].isLost==false) {
        float angle = TWO_PI*i/nCubes;
        float na = aMouse+angle;
        float tax = cx + r*cos(na);
        float tay = cy + r*sin(na);
        fill(255, 0, 0);
        ellipse(tax, tay, 10, 10);
        cubes[i].targetx = tax;
        cubes[i].targety = tay;
      }
    }
  } 

  if (spin) {
    motorControl(0, -100, 100, 30);
  }

  if (chase || mouseDrive) {
    //do the actual aim 
    for (int i = 0; i< nCubes; ++i) {
      if (cubes[i].isLost==false) {
        fill(0, 255, 0);
        ellipse(cubes[i].targetx, cubes[i].targety, 10, 10);
        aimCubeSpeed(i, cubes[i].targetx, cubes[i].targety);
      }
    }
  }


  //did we lost some cubes?
  for (int i=0; i<nCubes; ++i) {
    // 500ms since last update
    if (cubes[i].lastUpdate < now - 1500 && cubes[i].isLost==false) {
      cubes[i].isLost= true;
    }
  }
}

//helper functions to drive the cubes

boolean rotateCube(int id, float ta) {
  float diff = ta-cubes[id].deg;
  if (diff>180) diff-=360;
  if (diff<-180) diff+=360;
  if (abs(diff)<20) return true;
  int dir = 1;
  int strength = int(abs(diff) / 10);
  strength = 1;//
  if (diff<0)dir=-1;
  float left = ( 5*(1*strength)*dir);
  float right = (-5*(1+strength)*dir);
  int duration = 100;
  motorControl(id, left, right, duration);
  //println("rotate false "+diff +" "+ id+" "+ta +" "+cubes[id].deg);
  return false;
}

// the most basic way to move a cube
boolean aimCube(int id, float tx, float ty) {
  if (cubes[id].distance(tx, ty)<25) return true;
  int[] lr = cubes[id].aim(tx, ty);
  float left = (lr[0]*.5);
  float right = (lr[1]*.5);
  int duration = (100);
  motorControl(id, left, right, duration);
  return false;
}

boolean aimCubeSpeed(int id, float tx, float ty) {
  float dd = cubes[id].distance(tx, ty)/100.0;
  dd = min(dd, 1);
  if (dd <.15) return true;

  int[] lr = cubes[id].aim(tx, ty);
  float left = (lr[0]*dd);
  float right = (lr[1]*dd);
  int duration = (100);
  motorControl(id, left, right, duration);
  return false;
}

void keyPressed() {
  switch(key) {
  case 'm':
    mouseDrive = !mouseDrive;
    chase = false;
    spin = false;
    break;
  case 'c':
    chase = !chase;
    spin = false;
    mouseDrive = false;
    break;
  case 's':
    chase = false;
    mouseDrive = false;
    spin = false;
    break;
  case 'p':
    spin = !spin;
    chase = false;
    mouseDrive=false;
  case 'a':
    for (int i=0; i < nCubes; ++i) {
      aimMotorControl(i, 380, 260);
    }
    break;
  case 'l':
    light(0, 100, 255, 0, 0);
    break;
  default:
    break;
  }
}

//OSC messages (send)

void aimMotorControl(int cubeId, float x, float y) {
  int hostId = cubeId/cubesPerHost;
  int actualcubeid = cubeId % cubesPerHost;
  OscMessage msg = new OscMessage("/aim");
  msg.add(actualcubeid);
  msg.add((int)x);
  msg.add((int)y);
  oscP5.send(msg, server[hostId]);
}

void motorControl(int cubeId, float left, float right, int duration) {
  int hostId = cubeId/cubesPerHost;
  int actualcubeid = cubeId % cubesPerHost;
  OscMessage msg = new OscMessage("/motor");
  msg.add(actualcubeid);
  msg.add((int)left);
  msg.add((int)right);
  msg.add(duration);
  oscP5.send(msg, server[hostId]);
}

void light(int cubeId, int duration, int red, int green, int blue){
  int hostId = cubeId/cubesPerHost;
  int actualcubeid = cubeId % cubesPerHost;
  OscMessage msg = new OscMessage("/led");
  msg.add(actualcubeid);
  msg.add(duration);
  msg.add(red);
  msg.add(green);
  msg.add(blue);
  oscP5.send(msg, server[hostId]);
}


void mousePressed() {
  chase = false;
  spin = false;
  mouseDrive=true;
}

void mouseReleased() {
  mouseDrive=false;
}



//OSC message handling (receive)

void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/position") == true) {
    int hostId = msg.get(0).intValue();
    int id = msg.get(1).intValue();
    //int matId = msg.get(1).intValue();
    int posx = msg.get(2).intValue();
    int posy = msg.get(3).intValue();

    int degrees = msg.get(4).intValue();
    println("Host "+ hostId +" id " + id+" "+posx +" " +posy +" "+degrees);

    id = cubesPerHost*hostId + id;

    if (id < cubes.length) {
      cubes[id].count++;

      cubes[id].prex = cubes[id].x;
      cubes[id].prey = cubes[id].y;

      cubes[id].oidx = posx;
      cubes[id].oidy = posy;

      cubes[id].x = posx;
      cubes[id].y = posy;

      cubes[id].deg = degrees;

      cubes[id].lastUpdate = System.currentTimeMillis();
      if (cubes[id].isLost == true) {
        cubes[id].isLost = false;
      }
    }
  } else if (msg.checkAddrPattern("/button") == true) {
    int hostId = msg.get(0).intValue();
    int relid = msg.get(1).intValue();
    int id = cubesPerHost*hostId + relid;
    int pressValue =msg.get(2).intValue();
    println("Button pressed for id : "+id);
  }
}
