#include "sendAck.h"
#include "Timer.h"


configuration sendAckAppC {}

implementation {
/****** COMPONENTS *****/
  components MainC, sendAckC;
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC();

  
  components new FakeSensorC();
  
  
  //add the other components here

/****** INTERFACES *****/
  //Boot interface
  sendAckC.Boot -> MainC;
  //Interfaces to access package fields
  sendAckC.Packet -> AMSenderC;
  //Send and Receive interfaces
  sendAckC.AMSend -> AMSenderC;
  sendAckC.Receive -> AMReceiverC;
  //Radio Control
  sendAckC.SplitControl -> ActiveMessageC;
  //Timer Interface
  sendAckC.MilliTimer -> TimerMilliC;
  sendAckC.PacketAcknowledgements -> ActiveMessageC;
  //Fake Sensor read
  sendAckC.Read -> FakeSensorC;
  
}

