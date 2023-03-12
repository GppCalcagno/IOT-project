#include "project.h"
#include "Timer.h"
#include "string.h"


configuration projectAppC {}

implementation {
/****** COMPONENTS *****/
  components MainC, projectC;
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC() as MilliTimerC;
  components new TimerMilliC() as MissingTimerC;
  components new TimerMilliC() as InfoTimerC;
  components RandomC;
  

  
  
  //add the other components here

/****** INTERFACES *****/
  //Boot interface
  projectC.Boot -> MainC;
  //Interfaces to access package fields
  projectC.Packet -> AMSenderC;
  //Send and Receive interfaces
  projectC.AMSend -> AMSenderC;
  projectC.Receive -> AMReceiverC;
  //Radio Control
  projectC.SplitControl -> ActiveMessageC;
  projectC.PacketAcknowledgements -> ActiveMessageC;
  //Timer Interface
  projectC.MilliTimer -> MilliTimerC;
  projectC.MissingTimer -> MissingTimerC;
  projectC.InfoTimer -> InfoTimerC;

  
  //Random
  projectC.Random -> RandomC;
  RandomC <- MainC.SoftwareInit;
  
  
}

