#include "project.h"
#include "Timer.h"
#include "string.h"

module projectC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	//interfaces for communication
	interface AMSend;
	interface Packet;
	interface SplitControl;
	interface Receive;
	interface PacketAcknowledgements;
	
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	//interface for missing timer 
	interface Timer<TMilli> as MissingTimer;
	//interface for info timer
	interface Timer<TMilli> as InfoTimer;
	//interace to get a random Number
	interface Random;

  }

} implementation {
	
	uint16_t ID;	
    uint16_t associatedID;
  	char key[KEY_LEN];
	bool locked=0;
	message_t packet;
	
	uint8_t X;
	uint8_t Y;
	
	uint8_t ChildStatus;
	
	uint8_t i;
	
	void setKey();
	void sendBroadcast();  
	void sendMessStopPairing();
  	void createStatus();
  	//sim_time_string()
  	
  	void sendChildStatus();
  	
  	char* statusToString(uint8_t ChildStatus);
  	
  	char* statusToString(uint8_t ChildStatus){
  	if(ChildStatus==1)
  		return "STANDING";
  	if(ChildStatus==2)
  		return "WALKING";
  	if(ChildStatus==3)
  		return "RUNNING";
  	if(ChildStatus==4)
  		return "FALLING";
  	}
  	
  	

  //***************** Send Children Information Status ********************//
  void sendChildStatus(){
  	createStatus();
  	
  	if(!locked){
 	//prepare the message
 	msg_child* message = (msg_child*) call Packet.getPayload(&packet,sizeof(msg_child));
 	
 	message->msg_type = INFO;
 	message->X=X;
 	message->Y=Y;
 	message->status=ChildStatus;
 	
  	call PacketAcknowledgements.requestAck(&packet);
 	 
 //send unicast message
	if (call AMSend.send(associatedID ,&packet,sizeof(msg_child))==SUCCESS) {
		locked=1;	
	 	dbg("radio", "Child Bracelet %d send a unicast INFO message: Status (ack requested): %s, X=%d, Y=%d (%s)\n",ID,statusToString(ChildStatus),X,Y,sim_time_string());
	
 	}
 	
 	}
    
  }
  
  
  	
  //***************** Create Status Data ********************//	
  void createStatus(){
	uint8_t rnd = (call Random.rand16() % 10) + 1;
	
      if(rnd<=3){
         ChildStatus=STANDING;
      }
      else if(rnd<=6){
         ChildStatus=WALKING;
      }
      else if(rnd<=9){
         ChildStatus=RUNNING;
      }
      else if(rnd=10){
         ChildStatus=FALLING;
      }
      
      X = call Random.rand16() % 100;
      Y = call Random.rand16() % 100;
  }
  
  
  
  //***************** Send Stop Pairing  Message function ********************//	
  void sendMessStopPairing(){
  
    	if(!locked){
	 	//prepare the message
	 	msg_stop_paring* message = (msg_stop_paring*) call Packet.getPayload(&packet,sizeof(msg_stop_paring));
	 	
	 	message->msg_type = STOP_PAIRING;
	 	
	  	call PacketAcknowledgements.requestAck(&packet);

	 //send unicast message
		if (call AMSend.send(associatedID ,&packet,sizeof(msg_stop_paring))==SUCCESS) {
			locked=1;	
		 	dbg("radio", "Bracelet %d sent a unicast message (ack requested) to stop pairing phase to Bracelet  %d (%s)\n",ID,associatedID,sim_time_string());
		
	 }
	 }
  
  }  
  
  
  
  //***************** Send Broadcast  Message function ********************//
  void sendBroadcast(){
  
  	  if(!locked){
	 	//prepare the message
	 	msg_pairing* message = (msg_pairing*) call Packet.getPayload(&packet,sizeof(msg_pairing));
	 	
	 	message->msg_type = PAIRING;
	 	message->id = ID;
	 	
	 	for (i=0; i<KEY_LEN; i++){
			message->key[i]=key[i];
		}

	 if (call AMSend.send(AM_BROADCAST_ADDR ,&packet,sizeof(msg_pairing))==SUCCESS) {
		locked=1;	
	 	dbg("radio", "Bracelet %d sent a broadcast pairing message (%s)\n",ID,sim_time_string());
		
	 }
	 }
  
  }
   

  //***************** Set Key function ********************// 
  void setKey(){
	if(ID<2)
        strcpy(key, "D0oM6MyHqWigyH1paRl3");
    else
		strcpy(key, "NmZQODR76wjmwgLNLq45");  	
  }
  
  //***************** Boot interface ********************//
  event void Boot.booted() {

	ID = TOS_NODE_ID;
	setKey();
	
	dbg("boot","Bracelet %d with Key: %s booted at time: %s .\n",ID,key,sim_time_string());
	
	
	call SplitControl.start(); //start the radio
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
  
	if (err==SUCCESS){
    	dbg("radio", "Bracelet %d: Radio on (%s)!\n\n",ID,sim_time_string());
    	dbg("timer","Bracelet %d: Start Timer (%s)\n",ID,sim_time_string());
    	call MilliTimer.startPeriodic(BROADCAST_TIME);
    }
    else {
    	dbg("radio", "Bracelet %d: Can't Start the Radio, retry! (%s)\n",ID,sim_time_string());
    	call SplitControl.start();
    }

  }
  
  event void SplitControl.stopDone(error_t err){
    dbg("radio", "Bracelet %d: Can't Start the Radio! (%s)\n",ID,sim_time_string());
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
  	//pairing Phase
   	sendBroadcast();
   	
  }
  
  
  event void MissingTimer.fired() {
  	dbg("status", "Parent Bracelet %d receive a MISSING alarm. Last Pos: X=%d, Y=%d (%s)\n",ID,X,Y,sim_time_string());
  	//call MissingTimer.stop(); to change the behavior of the MISSING alarm
  
  }
  
  event void InfoTimer.fired() {
  	//Child Timer
 	 sendChildStatus();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* msg,error_t err) {
	
	if(&packet == msg && err==SUCCESS){
		//brodcast message don't require ack
		if((call Packet.payloadLength(msg)) != sizeof(msg_pairing)){
				 			
	 	if(call PacketAcknowledgements.wasAcked(msg)){
			dbg("radio", "Bracelet %d has received the message ACK!(%s)\n\n",ID,sim_time_string());
	 	} else {
	 		
	 		if((call Packet.payloadLength(msg)) == sizeof(msg_child)){
	 				//re-set the the ack 
	 				call PacketAcknowledgements.requestAck(msg);
	 				if (call AMSend.send(associatedID ,msg,sizeof(msg_child))==SUCCESS) {	
	 					dbg("radio", "ACK not Received: Child Bracelet %d send a unicast INFO message: Status: %s, X=%d, Y=%d (%s)\n",ID,statusToString(ChildStatus),X,Y,sim_time_string());
					}
					
	 		}
	 		
	 		if((call Packet.payloadLength(msg)) == sizeof(msg_stop_paring)){
	 				//re-set the the ack
	 				call PacketAcknowledgements.requestAck(msg);
	 				if (call AMSend.send(associatedID ,msg,sizeof(msg_pairing))==SUCCESS) {
	 					dbg("radio", "ACK not Received:Bracelet %d sent a unicast message to stop pairing phase to Bracelet %d (%s)\n",ID,associatedID,sim_time_string());
					}
	 		}
	 	
	 	
	 	} 
	 }	
  }
  	locked=0;
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
    	
  	if(len == sizeof(msg_pairing)) {

		// 1. Read the content of the message
		 	msg_pairing* message = (msg_pairing*) payload;
		 	char receivedKey[KEY_LEN];
			
			if(message->msg_type==PAIRING){
				//dbg("radio", "Bracelet %d has received a pairing message from %d !\n",ID,message->id);					 	
			 	
			 	for(i=0;i<KEY_LEN;i++){
			 		receivedKey[i]=message->key[i];
			 	}
			 							 		 	
			 	if(strcmp (receivedKey, key)==0){
			 	    dbg("status", "Bracelet %d matched with Bracelet %d !(%s)\n",ID,message->id,sim_time_string());
					associatedID=message->id;
			 	    sendMessStopPairing();

			 	    
			 	    
			 	}	
			 }
	 }
	 
	 if(len == sizeof(msg_stop_paring)) {
	 	msg_pairing* message = (msg_pairing*) payload;
	 	
	 	if(message->msg_type==STOP_PAIRING){
	 		dbg("radio", "Bracelet %d has received a stop pairing message!(%s)\n",ID,sim_time_string());
	 		call MilliTimer.stop();
	 		dbg("status", "Bracelet %d stopped the pairing phase!(%s)\n",ID,sim_time_string());
	 		
	 		//start the second phase 
	 		if(ID%2==1){
	 		//odd numbers are children
	 		    dbg("timer","Child Bracelet %d: Start Periodical Timer (%d ms) (%s)\n",ID,CHILD_TIME,sim_time_string());
    			call InfoTimer.startPeriodic(CHILD_TIME);	
	 		
	 		}
	 		 		
	 	}
	 }
	 
	 if(len == sizeof(msg_child)) {
	 	msg_child* message = (msg_child*) payload;
	 	dbg("radio", "Parent Bracelet %d has received a INFO  message!(%s)\n",ID,sim_time_string());
	 	
	 	X= message->X;
	 	Y= message->Y;
	 	
	 	if(message->msg_type==INFO){
		 	if(message->status==FALLING){
		 		dbg("status", "Parent Bracelet %d has received a FALL alarm: STATUS=%s, X=%d, Y=%d! (%s)\n",ID,statusToString(message->status),message->X,message->Y,sim_time_string());
		 	}
		 	
		 	call MissingTimer.stop();
		 	call MissingTimer.startPeriodic(PARENT_TIME);
	 	}
	 	
	 }
	 
	
	
	return buf;

  }
  
}

