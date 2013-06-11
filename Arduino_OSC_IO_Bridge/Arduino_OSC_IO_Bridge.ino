/*
  ______ ______ __   __      __     __ ______ __  __ ______ __  __ ______  
 /\  ___\\  == \\ "-.\ \    /\ \  _ \ \\  == \\ \/ / \  ___\\ \_\ \\  == \ 
 \ \ \____\  __< \ \-.  \   \ \ \/ ".\ \\  __< \  _"-.\___  \\  __ \\  _-/ 
 .\ \_____\\_____\\ \_\\"\   \ \ \__/".~\\ \_\ \\ \_\ \\_____\\_\ \_\\_\   
 ..\/_____//_____//_/ \/_/    \/_/   \/_//_/ /_//_/\/_//_____//_/\/_//_/   
 
 ---What?---
 Arduino to UDP/OSC I/O Bridge for Interactive Controllers
 v1.0
 Tested on ATMega 328 Duemilanove w/ Seeedstudio Ethernet Shield using 50' CAT5e UTP
 with Arduino_OSC_IO_Bridge_Test_Host.PDE v1.0 controller
 
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
 Oscuino Samples & Library by Yotam Mann and Adrian Freed @ CNMAT
 
 ---When?---
 2013-06-10                                                                                        
 */

#include <Ethernet.h>
#include <EthernetUdp.h>
#include <SPI.h>
#include <OSCBundle.h>
#include <OSCData.h>
#include <OSCMatch.h>
#include <OSCMessage.h>



EthernetUDP Udp;

// the Arduino's IP
IPAddress ip(10, 0, 0, 235);

// host computer IP
IPAddress hostIP(10, 0, 0, 237);

//port numbers
const unsigned int inPort = 8888;
const unsigned int outPort = 9999;

//delay between checking sensor values
const unsigned int dataDelay = 50; //ms between sampling sessions, if no triggers

//pin counts
byte aPinCount = 6;
byte aPin[] = {
  A0, A1, A2, A3, A4, A5 };

byte dPinCount = 2;
byte dPin[] = {
  2, 3};

void read_mac() {}
 byte mac[] = {  
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; 

//converts the pin to an osc address
char * numToOSCAddress( int pin){
    static char s[10];
    int i = 9;
	
    s[i--]= '\0';
	do
    {
		s[i] = "0123456789"[pin % 10];
                --i;
                pin /= 10;
    }
    while(pin && i);
    s[i] = '/';
    return &s[i];
}

void setup() {
  //setup ethernet port
  read_mac();
  Ethernet.begin(mac,ip);
  Udp.begin(inPort);
  
  //setup GPIO pins
    for(byte a = 0; a < aPinCount; a++){
        pinMode(aPin[a], INPUT);
        //digitalWrite(aPin[a], HIGH); //enable analog pin pullups
  }
    for(byte d = 0; d < dPinCount; d++){
        pinMode(dPin[d], OUTPUT);
        digitalWrite(dPin[d], LOW); //set starting output pins LOW
  }
  
  //***debugging printout of IP address (works with DHCP
  Serial.begin(19200);
  Serial.println("Ready.");
  // print your local IP address:
  Serial.print("Arduino @ ");
  for (byte thisByte = 0; thisByte < 4; thisByte++) {
    // print the value of each byte of the IP address:
    Serial.print(Ethernet.localIP()[thisByte], DEC);
    Serial.print(" "); 
  }
  Serial.print("port ");
  Serial.println(inPort);

}
    
void readPins(){
    //pack an OSC bundle of the sensor values
    OSCBundle bndl;
      bndl.add("/sensors/0").add((int32_t)analogRead(0));
      bndl.add("/sensors/1").add((int32_t)analogRead(1));
      bndl.add("/sensors/2").add((int32_t)analogRead(2));
      bndl.add("/sensors/3").add((int32_t)analogRead(3));
      bndl.add("/sensors/4").add((int32_t)analogRead(4));
      bndl.add("/sensors/5").add((int32_t)analogRead(5));
    
    //send the bundle  
    Udp.beginPacket(hostIP, outPort);
      bndl.send(Udp); // send the bytes to UDP
    Udp.endPacket(); // mark the end of the OSC Packet
      bndl.empty(); // free space for new bundle
    
    //say we're done with the bundle **disable if not needed
    OSCMessage msg("/sensors/DONE"); //all analog pins read
    Udp.beginPacket(hostIP, outPort);
    msg.send(Udp); // send the bytes to UDP
    Udp.endPacket(); // mark the end of the OSC Packet
    msg.empty(); // free space occupied by message
    //**debug printout
    //Serial.print(">>>>> sent sensor completion OSC packet to ");
    //Serial.print(hostIP);
    //Serial.print(":");
    //Serial.println(outPort);
    
}  

void loop(){ 
   OSCMessage messageIN;
   int size;
   if( (size = Udp.parsePacket())>0) //are there any messages waiting to be processed?
   {
     //Serial.println("<<<<< received OSC packet");
     while(size--)
       messageIN.fill(Udp.read());
    if(!messageIN.hasError())
     {
       //Serial.println("made it past error filter"); 
        messageIN.route("/triggers", routeTriggers);
    }
   }
    else{ //no messages, read the pins and send values
    //Serial.println("@@@@@@ no packets, send sensor readings");
      readPins();
      delay(dataDelay);
    }
}

void routeTriggers(OSCMessage &msg, int addrOffset ){
  Serial.println("Trigger signal received");
  if (msg.fullMatch("/2", addrOffset)){
    if (msg.isInt(0)){
        int i = msg.getInt(0);
        digitalWrite(2, (i > 0)? HIGH: LOW);
  }
  }
  else if (msg.fullMatch("/3", addrOffset)){
    if (msg.isInt(0)){
        int i = msg.getInt(0);
        digitalWrite(3, (i > 0)? HIGH: LOW);
}
  }
}







