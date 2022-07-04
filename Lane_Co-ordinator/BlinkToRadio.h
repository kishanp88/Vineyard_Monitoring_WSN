#ifndef BLINKTORADIO_H
#define BLINKTORADIO_H

enum {
  AM_BLINKTORADIO = 1,
  TIMER_PERIOD_MILLI_NODE = 5000,
  //TIMER_PERIOD_MILLI_COTR = 5000,
  CO_ORDINATOR_ID = 1,
  MULE_ID = 18,
  SET_NODE_POWER = 11,
  SET_COTR_POWER = 1
};

typedef nx_struct NodeData {
  nx_uint8_t snodeid;
  nx_uint16_t dataindex;
  nx_uint8_t temperature;
  nx_uint8_t humidity;

} NodeData;

typedef nx_struct BlinkToRadioMsg {
  nx_uint8_t snodeid;
  nx_uint8_t dnodeid;
  nx_uint8_t temperature;
  nx_uint8_t humidity;
  NodeData lanedata[3];
  //nx_uint16_t timeinsec;
  nx_uint8_t storeindex;

} BlinkToRadioMsg;







#endif
