#ifndef PROJECT_H
#define PROJECT_H

//type of messages
#define STOP_PAIRING 0
#define PAIRING 1
#define INFO 2

//20 char + terminator
#define KEY_LEN 22

//type of status
#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4

//timer times
#define BROADCAST_TIME 7000
#define CHILD_TIME 10000
#define PARENT_TIME 60000




//payload of the msg
typedef nx_struct msg_pairing {
	nx_uint16_t msg_type;
	nx_uint8_t key[KEY_LEN];
	nx_uint16_t id;
} msg_pairing;

typedef nx_struct msg_stop_paring {
	nx_uint16_t msg_type;
} msg_stop_paring;

typedef nx_struct msg_child {
	nx_uint16_t msg_type;
	nx_uint16_t X;
	nx_uint16_t Y;
	nx_uint16_t status;
} msg_child;



enum{
AM_MY_MSG = 6
};


#endif
