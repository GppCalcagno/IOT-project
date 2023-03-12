/*
 * Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "printf.h"	
#include "Timer.h"
module Challenge3C{
  uses interface Boot;
  uses interface Timer<TMilli>;
  uses interface Leds;
  }

implementation {

  uint64_t PersonalCode = 10548612;
  uint32_t rem;
  bool l0;
  bool l1;
  bool l2;
  

  event void Boot.booted() {
    call Timer.startPeriodic(60000);
    call Leds.led0Off();
  	call Leds.led1Off();
    call Leds.led2Off();
    l0=0;
    l1=0;
    l2=0;	
  }

  event void Timer.fired(){
  
  rem= PersonalCode%3;
  PersonalCode=PersonalCode/3;
  
  if(rem==0){
  	call Leds.led0Toggle();
  	l0=!l0;
  }
  
  if(rem==1){
  	call Leds.led1Toggle();
  	l1=!l1;
  }
  	
  if(rem==2){
  	call Leds.led2Toggle();
  	l2=!l2;
  }
  		
 	
  printf("%i,%i,%i\n",l0,l1,l2);
  printfflush();
  
  if(PersonalCode==0)
  	call Timer.stop();
  		
  }
}
