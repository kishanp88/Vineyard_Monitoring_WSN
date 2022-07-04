//node to node - sending from 4(Node) to 3(Node) to 2(LC)
#include <Timer.h>
#include "printf.h"
#include "BlinkToRadio.h"
#define LANE1 1
#define LANE2 4
#define LANE3 7
#define LANE4 9
#define LANE5 11
#define LANE6 14
#define MULEID 18
#define BASEID 21
nx_uint16_t temp,i;


module BlinkToRadioC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface Receive;
  uses interface SplitControl as AMControl;
  uses interface CC2420Packet;
}
implementation {

  uint16_t counter,fcounter, node0index, node1index, node2index, storeindex;
  message_t pkt;
  nx_uint16_t s1node, temperature1,i,base_station_counter;
  
  NodeData dataStore[50];
  bool busy = FALSE;
  bool mule_flag  = TRUE;
  bool base_station_flag  = FALSE;

  bool lane1_flag = FALSE;
  bool lane2_flag = FALSE;
  bool lane3_flag = FALSE;
  bool lane4_flag = FALSE;
  bool lane5_flag = FALSE;
  bool lane6_flag = FALSE;
  bool *lane_send_flag;

  /*bool send_lane1_flag = FALSE;
  bool send_lane2_flag = FALSE;
  bool send_lane3_flag = FALSE;
  bool send_lane4_flag = FALSE;
  bool send_lane5_flag = FALSE;
  bool send_lane6_flag = FALSE;*/

  StoreData Lane1,Lane2,Lane3,Lane4,Lane5,Lane6, LaneSend;

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
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_NODE);
      else
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI_COTR);  
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }

  event void Timer0.fired() {
    
    if(base_station_flag == TRUE)
    {
      base_station_counter++;
      switch(base_station_counter)
      {
        case 1: LaneSend = Lane1; lane_send_flag = &lane1_flag; break;
        case 2: LaneSend = Lane2; lane_send_flag = &lane2_flag; break;
        case 3: LaneSend = Lane3; lane_send_flag = &lane3_flag; break;
        case 4: LaneSend = Lane4; lane_send_flag = &lane4_flag; break;
        case 5: LaneSend = Lane5; lane_send_flag = &lane5_flag; break;
        case 6: LaneSend = Lane6; lane_send_flag = &lane6_flag; base_station_flag = FALSE;base_station_counter = 0; break;
      }

if (!busy) 
{
      BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
          if (btrpkt == NULL)
          {
            return;
          }
          if(*lane_send_flag == TRUE)
          {
            setLeds(0x05);
            btrpkt->snodeid = MULEID;
            btrpkt->dnodeid = BASEID;
            btrpkt->storeindex = LaneSend.storeindex;
            *lane_send_flag = FALSE;
            for(i=0;i<=LaneSend.storeindex;i++)
            {
             btrpkt->lanedata[i] = LaneSend.lanedata[i];

            }
            call CC2420Packet.setPower(&pkt,SET_COTR_POWER);
            //printf("i is %d",i);
            if (call AMSend.send(AM_BROADCAST_ADDR,&pkt, sizeof(BlinkToRadioMsg)) == SUCCESS)
            {   
              printf("----sending data to base station----\n");
              //printf("time is %d sec\n",timeinsec);      
              
              busy = TRUE;
            }

          }
          setLeds(0x00);
        }


    }
    else
    {
    if (!busy) {
  BlinkToRadioMsg* btrpkt = 
  (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
      if (btrpkt == NULL) {
  return;
      }
      btrpkt->snodeid = TOS_NODE_ID;
      call CC2420Packet.setPower(&pkt,SET_COTR_POWER);
            if (call AMSend.send(AM_BROADCAST_ADDR, 
          &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
          
              //printf("{temperature = %d, nodeid = %d}", 30, 4);
        busy = TRUE;
        }
    }
  }
  }

  event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
         busy = FALSE;

   }
    //setLeds(0x00);
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
if (len == sizeof(BlinkToRadioMsg)){
    BlinkToRadioMsg* btrpkt     = (BlinkToRadioMsg*)payload;
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE1 && lane1_flag == FALSE))
        {
            lane1_flag = TRUE;
            Lane1.storeindex = btrpkt->storeindex;
            //Lane1.laneid = LANE1;
            printf("Receiveing\n");
            //printf("storeindex %d laneid %d\n",Lane1.storeindex,Lane1.laneid);
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane1.lanedata[i] = btrpkt->lanedata[i];

            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane1.lanedata[i].snodeid,Lane1.lanedata[i].temperature,Lane1.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE2 && lane2_flag == FALSE))
        {
            lane2_flag = TRUE;
            Lane2.storeindex = btrpkt->storeindex;
            //Lane2.laneid = LANE2;            
            printf("Receiveing\n");
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane2.lanedata[i] = btrpkt->lanedata[i];
            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane2.lanedata[i].snodeid,Lane2.lanedata[i].temperature,Lane2.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE3 && lane3_flag == FALSE))
        {
            lane3_flag = TRUE;
            Lane3.storeindex = btrpkt->storeindex;
            //Lane3.laneid = LANE3;            
            printf("Receiveing\n");
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane3.lanedata[i] = btrpkt->lanedata[i];
            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane3.lanedata[i].snodeid,Lane3.lanedata[i].temperature,Lane3.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE4 && lane4_flag == FALSE))
        {
            lane4_flag = TRUE;
            Lane4.storeindex = btrpkt->storeindex;
            //Lane4.laneid = LANE4;             
            printf("Receiveing\n");
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane4.lanedata[i] = btrpkt->lanedata[i];
            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane4.lanedata[i].snodeid,Lane4.lanedata[i].temperature,Lane4.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE5 && lane5_flag == FALSE))
        {
            lane5_flag = TRUE;
            Lane5.storeindex = btrpkt->storeindex;
            //Lane5.laneid = LANE5;             
            printf("Receiveing\n");
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane5.lanedata[i] = btrpkt->lanedata[i];
            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane5.lanedata[i].snodeid,Lane5.lanedata[i].temperature,Lane5.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == LANE6 && lane6_flag == FALSE))
        {
            lane5_flag = TRUE;
            Lane6.storeindex = btrpkt->storeindex;
            //Lane6.laneid = LANE6;             
            printf("Receiveing\n");
            for(i=0;i<=btrpkt->storeindex;i++){
                Lane6.lanedata[i] = btrpkt->lanedata[i];
            }
            for(i=0;i<=btrpkt->storeindex;i++){
                printf("SNodeID %d temperature %d humidity %d storeindex %d\n",Lane6.lanedata[i].snodeid,Lane6.lanedata[i].temperature,Lane6.lanedata[i].humidity,btrpkt->storeindex);
            }  
        }
        if((btrpkt->dnodeid == MULEID && btrpkt->snodeid == BASEID))//Base Station send
        {
          base_station_flag = TRUE;
          /*BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
          if (btrpkt == NULL)
          {
            return;
          }
          if(lane1_flag == TRUE)
          {
            setLeds(0x05);
            btrpkt->snodeid = MULEID;
            btrpkt->dnodeid = BASEID;
            lane1_flag = FALSE;
            for(i=0;i<=Lane1.storeindex;i++)
            {
             btrpkt->lanedata[i] = Lane1.lanedata[i];

            }
            call CC2420Packet.setPower(&pkt,SET_COTR_POWER);
            //printf("i is %d",i);
            if (call AMSend.send(MULE_ID,&pkt, sizeof(BlinkToRadioMsg)) == SUCCESS)
            {   
              printf("----sending data to base station----\n");
              //printf("time is %d sec\n",timeinsec);      
              
              busy = TRUE;
            }

          }
          setLeds(0x00);*/
        }
    }
        return msg;    //-----------------
}
}
