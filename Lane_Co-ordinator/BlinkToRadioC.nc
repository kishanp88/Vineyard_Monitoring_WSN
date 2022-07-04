//node to node - sending from 4(Node) to 3(Node) to 2(LC)
#include <Timer.h>
#include "printf.h"
#include "BlinkToRadio.h"

module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface CC2420Packet;
}
implementation {

  nx_uint16_t counter,fcounter, node0index, node1index, node2index, storeindex,  timeinsec;
  message_t pkt;
  nx_uint8_t s1node, temperature1,i,j,k, mule_dataindex, humidity1;
  //BlinkToRadioMsg* dataStore[50][50];


  NodeData dataStore[50];
  bool busy = FALSE;
  bool mule_flag = TRUE;

  void setLeds(uint16_t val) {
    if (val & 0x01)
      call Leds.led0On();
    else 
      call Leds.led0Off();
    if (val & 0x02)
      call Leds.led1On();
    else
      call Leds.led1Off();
    if (val & 0x04)
      call Leds.led2On();
    else
      call Leds.led2Off();
  }

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if(TOS_NODE_ID != CO_ORDINATOR_ID)
      {
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_NODE);
      call Timer1.startPeriodic(1000);
    } 
      else
      {
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_NODE);
      call Timer1.startPeriodic(1000);  
    }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired() {
    counter++;
    if(TOS_NODE_ID != CO_ORDINATOR_ID){
    if (!busy) {
  BlinkToRadioMsg* btrpkt = 
  (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
  return;
      }
      btrpkt->snodeid = TOS_NODE_ID;
      btrpkt->dnodeid = TOS_NODE_ID - 1;
      btrpkt->temperature = 31;
      btrpkt->humidity = 22;
      call CC2420Packet.setPower(&pkt,SET_NODE_POWER);
            if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
          printf("data of node %d sent to node %d || temperature: %d || humidity: %d\n", btrpkt->snodeid, btrpkt->dnodeid, btrpkt->temperature, btrpkt->humidity);
              //printf("{temperature = %d, nodeid = %d}", 30, 4);
        busy = TRUE;
        }
    }
  }
    else
    {
      dataStore[0].snodeid = TOS_NODE_ID;
      dataStore[0].dataindex = node0index; 
      dataStore[0].temperature = 29;
      dataStore[0].humidity = 23;
      printf("Data of node %d is saved\n", TOS_NODE_ID);
      //storeindex++;
      node0index++;
    }
  }

  event void Timer1.fired(){
    timeinsec++;
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
         busy = FALSE;
         //printf("sending Done\n");
   }
   if(TOS_NODE_ID == CO_ORDINATOR_ID)
   {
    mule_flag = TRUE;
    setLeds(0x00);
    mule_dataindex++;
    if(mule_dataindex > 3)
    storeindex = 0;
    printf("sending Done\n");

   }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    uint16_t i;
    if (len == sizeof(BlinkToRadioMsg)) {
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;

    if(btrpkt->snodeid == MULE_ID && TOS_NODE_ID == CO_ORDINATOR_ID && mule_flag) //data mule id
    { 
      printf("inside mule box\n");
     //if(storeindex !=0)
     {
      mule_flag = FALSE;
      {
          if (!busy) 
      {
            BlinkToRadioMsg* btrpkt = 
        (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
        return;
            }
            setLeds(0x05);
            
            for(i=0;i<=storeindex;i++)
              {btrpkt->lanedata[i] = dataStore[i];}
            for(i=0;i<=storeindex;i++) 
              {printf("----sending data from node %d temperature %d , humidity %d , to mule dataindex %d---\n", btrpkt->lanedata[i].snodeid, btrpkt->lanedata[i].temperature,
                btrpkt->lanedata[i].humidity,btrpkt->lanedata[i].dataindex);}
            btrpkt->snodeid = TOS_NODE_ID;
            btrpkt->dnodeid = MULE_ID;
            btrpkt->storeindex = storeindex;
            //btrpkt->timeinsec = timeinsec;
            call CC2420Packet.setPower(&pkt,SET_COTR_POWER);
            //printf("i is %d",i);
                  if (call AMSend.send(MULE_ID, 
                &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {   
              printf("----sending data to data mule----\n");
              //printf("time is %d sec\n",timeinsec);      
              
              busy = TRUE;
            }
          }
        }  

    }
    } 
  
    else if (btrpkt->dnodeid == TOS_NODE_ID && TOS_NODE_ID != CO_ORDINATOR_ID)
   {
     setLeds(0x05);
     s1node = btrpkt->snodeid;
     temperature1 = btrpkt->temperature;
     humidity1 = btrpkt->humidity;
     printf("Data Received from node %d : Temperature = %d, humidity = %d\n", s1node, temperature1, humidity1);
     if (!busy) {
      BlinkToRadioMsg* btrpkt = 
  (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
  return;
      }
      btrpkt->snodeid = s1node;
      btrpkt->dnodeid = TOS_NODE_ID-1;
      btrpkt->temperature = temperature1;
      btrpkt->humidity = humidity1;
      call CC2420Packet.setPower(&pkt,SET_NODE_POWER);
            if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
        printf("Data Received from node %d sent to node %d || temperature : %d || humidity :%d\n", s1node, btrpkt->dnodeid, temperature1, humidity1);
        busy = TRUE;
      }
    }
    }
    else if (btrpkt->dnodeid == TOS_NODE_ID && TOS_NODE_ID == CO_ORDINATOR_ID)
    {
      s1node = btrpkt->snodeid;
      temperature1 = btrpkt->temperature;
      humidity1 = btrpkt->humidity;
      printf("Data Received from node %d : Temperature = %d, humidity = %d\n", s1node, temperature1, humidity1);
      //dataStore[storeindex].snodeid = s1node;
      //dataStore[storeindex].temperature = temperature1;
      if(s1node == CO_ORDINATOR_ID+1)
      {
        dataStore[1].snodeid = s1node;
        dataStore[1].temperature = temperature1;
        dataStore[1].humidity = humidity1;
        dataStore[1].dataindex = node1index;
        node1index++;
        if(storeindex != 2)
        storeindex = 1;
      }  
      if(s1node == CO_ORDINATOR_ID+2)
      {
        dataStore[2].snodeid = s1node;
        dataStore[2].temperature = temperature1;
        dataStore[2].humidity = humidity1;
        dataStore[2].dataindex = node2index;
        node2index++;
        storeindex = 2;
      }
      //storeindex++;
      /*if(storeindex == 20 || storeindex == 40 || storeindex == 60 || storeindex == 80)
      {
      printf("-------------------------------------\n");
      for(i=0;i<storeindex;i++)
      {
      //printf("temperature: %d, index: %d",dataStore[0][i] -> temperature, i);
       printf("snodeid : %d, temperature: %d, index: %d \n",dataStore[i].snodeid, dataStore[i].temperature,dataStore[i].dataindex);
      }
      printf("-----------thanks------------------\n");
      }*/
      
    }
    
    return msg;
  }
}
}
