/*
  ______ ______ __   __      __     __ ______ __  __ ______ __  __ ______  
 /\  ___\\  == \\ "-.\ \    /\ \  _ \ \\  == \\ \/ / \  ___\\ \_\ \\  == \ 
 \ \ \____\  __< \ \-.  \   \ \ \/ ".\ \\  __< \  _"-.\___  \\  __ \\  _-/ 
 .\ \_____\\_____\\ \_\\"\   \ \ \__/".~\\ \_\ \\ \_\ \\_____\\_\ \_\\_\   
 ..\/_____//_____//_/ \/_/    \/_/   \/_//_/ /_//_/\/_//_____//_/\/_//_/   
 
 ---What?---
 Arduino to UDP/OSC I/O Bridge Test Host for Interactive Controllers
 v1.0
 Tested on ATMega 328 Duemilanove w/ Seeedstudio Ethernet Shield using 50' CAT5e UTP
 running Arduino_OSC_IO_Bridge.INO v1.0
 
 ---Why?---
 To easily pass analog sensor data (0-5VDC, represented as 0-1023) to OSC hosts,
 and be able to implement local effects such as triggering a relay via remote triggers.
 
 ---How?---
 1. Configure IPs and ports for the arduino and host computer
 2. Connect analog voltage sources (sensors) to A0-A5 pins, if needed enable line 92 to
 enable pullups on analog input pins
 3. Connect triggerable devices (<20mA draw) to digital pins 2 and 3 -- more can be enabled
 4. Use any OSC source to tx/rx messages (packets) or bundles of messages to the IP and port
 of the arduino. Analog pins map to /sensors/0 - 5 and carry an int between 0 and 1023. Digital
 pins map to /triggers/2 and /3, and are turned HIGH by an argument [1] or LOW by a [0].
 5. A processing "host" can be used for testing. It is called "Arduino OSC IO Bridge Test Host"
 
 ---Who?---
 Gustavo Huber - gush@carbonworkshop.com
 based on oscP5sendreceive, http://www.sojamo.de/oscP5
 
 ---When?---
 2013-06-10                                                                                        
 */
 
import oscP5.*;
import netP5.*;
  
OscP5 oscP5;
NetAddress myRemoteLocation;

int dataFrame = 0;
int value0 = 0;
int value1 = 0;
int value2 = 0;
int value3 = 0;
int value4 = 0;
int value5 = 0;
int LClickColor = 255;
int RClickColor = 255;
int sfactor = 1023/340; //set maximum bar graph length

void setup() {
  size(380,250);
  /* start oscP5, listening for incoming messages at port 9999 */
  oscP5 = new OscP5(this,9999);
  
  myRemoteLocation = new NetAddress("10.0.0.235",8888);
}


void draw() {
  background(200);
  fill(180, 190, 180);
  rect(15, 3, 350, 125);
  fill(0);
  rect(20, 8, value0/sfactor, 15);
  rect(20, 28, value1/sfactor, 15);
  rect(20, 48, value2/sfactor, 15);
  rect(20, 68, value3/sfactor, 15);
  rect(20, 88, value4/sfactor, 15);
  rect(20, 108, value5/sfactor, 15);
  fill(255);
  text("/sensors/0: "+value0, 20, 20);
  text("/sensors/1: "+value1, 20, 40);
  text("/sensors/2: "+value2, 20, 60);
  text("/sensors/3: "+value3, 20, 80);
  text("/sensors/4: "+value4, 20, 100);
  text("/sensors/5: "+value5, 20, 120);
  fill(LClickColor);
  text("L CLICK = /triggers/2", 20, 180);
  fill(RClickColor);
  text("R CLICK = /triggers/3", 20, 200);
  fill(150);
  text("Connected to: "+myRemoteLocation+", frame "+dataFrame, 20, 230);
  
}

void mousePressed() {
  if (mouseButton == LEFT) {
  LClickColor = 0;
  //**debug printout
  //println("+++ sent an osc message '/triggers/2 [1]'");
  OscMessage myMessage = new OscMessage("/triggers/2");
  myMessage.add(1); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); /* send the message */
  } else if (mouseButton == RIGHT) {
  RClickColor = 0;
  //**debug printout
  //println("+++ sent an osc message '/triggers/3 [1]'");
  OscMessage myMessage = new OscMessage("/triggers/3");
  myMessage.add(1); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); /* send the message */
  } else {
    background(255,0,0); //flash red if unknown click
  }
}

void mouseReleased() { //set trigger int back to [0] on mousebutton release
  if (mouseButton == LEFT) {
  LClickColor = 255;  
  //**debug printout
  //println("+++ sent an osc message '/triggers/2 [0]'");
  OscMessage myMessage = new OscMessage("/triggers/2");
  myMessage.add(0); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); /* send the message */
  } else if (mouseButton == RIGHT) {
  RClickColor = 255;
  //**debug printout
  //println("+++ sent an osc message '/triggers/3 [0]'");
  OscMessage myMessage = new OscMessage("/triggers/3");
  myMessage.add(0); /* add an int to the osc message */
  oscP5.send(myMessage, myRemoteLocation); /* send the message */
  } else {
    background(255, 0, 0); // flash red if unknown click release
  }
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  //print("### received an osc message.");
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //print(" typetag: "+theOscMessage.typetag());
  //println(" message: "+theOscMessage.get(0).intValue());
  
    if(theOscMessage.checkAddrPattern("/sensors/0")==true) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      value0 = theOscMessage.get(0).intValue();  
      return;
  }
    else if(theOscMessage.checkAddrPattern("/sensors/1")==true) {
      value1 = theOscMessage.get(0).intValue();  
      return;
  }
    else if(theOscMessage.checkAddrPattern("/sensors/2")==true) {
      value2 = theOscMessage.get(0).intValue();  
      return;
  }
    else if(theOscMessage.checkAddrPattern("/sensors/3")==true) {
      value3 = theOscMessage.get(0).intValue();  
      return;
  }
    else if(theOscMessage.checkAddrPattern("/sensors/4")==true) {
      value4 = theOscMessage.get(0).intValue();  
      return;
  }
    else if(theOscMessage.checkAddrPattern("/sensors/5")==true) {
     value5 = theOscMessage.get(0).intValue();  
      return;
  }
      else if(theOscMessage.checkAddrPattern("/sensors/DONE")==true) {
      dataFrame = dataFrame+1;
      return;
  }
}


