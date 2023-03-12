

/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

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
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t last_digit = 3;
  uint8_t counter=0;
  uint8_t rec_id;
  uint8_t receivedAck=0;
  message_t packet;
  bool locked=0;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	  if(!locked){
	 	//prepare the message
	 	my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(&packet,sizeof(my_msg_t));
	 	
	 	rcm->msg_counter = counter;
	 	rcm->msg_type = REQ;
	 	rcm->value = 0;
	 	dbg("radio", "Create Packet n: %d!\n",counter);
	 	//Set the Ack falag
	 	if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
	 		dbg("radio", "ACK request settleds!\n");
	 	};
	 	
	 	
	 
	 //send unicast message
	 //receiver = 2 beause the TOS receiver is the 2
	 if (call AMSend.send(2 ,&packet,sizeof(my_msg_t))==SUCCESS) {
	 	locked=1;
	 	dbg("radio", "REQ Packet n: %d sent at time: %s \n",counter,sim_time_string());
		counter++;
	 }
	 }
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raises the event read done.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application %d booted at time: %s .\n",TOS_NODE_ID,sim_time_string());
	rec_id = TOS_NODE_ID;
	
	call SplitControl.start(); //start the radio
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if (err==SUCCESS){
    	dbg("radio", "Radio on!\n");
    	//timer is active only in TOS1 to send message
    	if(TOS_NODE_ID==1){
    		dbg("timer","Timer started for Node 1 (1000m).\n");
    		call MilliTimer.startPeriodic(1000);
    	}
    }
    else {
    	dbg("radio", "Can't Start the Radio, retry!\n");
    	call SplitControl.start();
    }
    
  }
  
  event void SplitControl.stopDone(error_t err){
    dbg("radio", "Can't Start the Radio!\n");
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
	 
	 //only active in TOSID1
	 sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer according to your id. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 locked=0;
	 if(TOS_NODE_ID==1){
		 
		 if(&packet == buf && err==SUCCESS){
		 	my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(buf,sizeof(my_msg_t));
		 			
		 	if(call PacketAcknowledgements.wasAcked(buf)){
		 		receivedAck++;
		 		dbg("radio", "Packet ACK n: %d received - Number of ACK: %d!\n",rcm->msg_counter,receivedAck);
		 		
		 		if(receivedAck == last_digit){
		 		dbg("timer", "Timer Stopped, Ack Received: %d !\n",receivedAck);
		 			call MilliTimer.stop();
		 		}
		 			
		 	}
		 	
		 	else{
		 		dbg("radio", "Packet ACK n:  %d NOT received !\n",rcm->msg_counter);

		 	}
		 
		 
		 }
	 }else{
		 if(&packet == buf && err==SUCCESS){
		 	my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(buf,sizeof(my_msg_t));
 		 	if(call PacketAcknowledgements.wasAcked(buf)){
		 		receivedAck++;
		 		dbg("radio", "Packet REQUEST n: ACK %d received !\n",rcm->msg_counter);	
		 	}
	 }
	 
  }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
  
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */		 
	if(len == sizeof(my_msg_t)) {
	// 1. Read the content of the message
		 	my_msg_t* rcm = (my_msg_t*) payload;
		 	
		 	if(TOS_NODE_ID==2){
		 	//2. Check if the type is request (REQ)
		 	if(rcm->msg_type==REQ){
		 	//3. If a request is received, send the response
			 	counter = rcm->msg_counter;
			 	sendResp();
		 	}
		 	}

	
	 	dbg("radio", "Message received from Node : %d \n",TOS_NODE_ID);
	 	if(rcm->msg_type==REQ){
		 	dbg("radio", "Type = REQ, Counter=%d \n\n",rcm->msg_counter);
	 	}else{
		 	dbg("radio", "Type = RES, Counter=%d, Value=%d \n\n",rcm->msg_counter,rcm->value);
	 }
	}
	return buf;
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finishes to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	 
	 	my_msg_t* rcm = (my_msg_t*) call Packet.getPayload(&packet,sizeof(my_msg_t));
	 	
	 	rcm->msg_counter = counter;
	 	rcm->msg_type = RESP;
	 	rcm->value = data;
	 	dbg("radio", "Create RESPONSE to Packet n: %d !\n",counter);
	 	//Set the Ack falag
	 	if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
	 		dbg("radio", "ACK request settleds!\n");
	 	}
	 	
	 	
	 
	 //send unicast message
	 //receiver = 2 beause the TOS receiver is the 2
	 if (call AMSend.send(1 ,&packet,sizeof(my_msg_t))==SUCCESS) {
	 	locked=1;
	 	dbg("radio", "RESP Packet n: %d sent at time: %s \n",counter,sim_time_string());
		counter++;
	 }

}
}

