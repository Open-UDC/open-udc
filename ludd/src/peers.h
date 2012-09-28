/* peers.h - header file for peers management
*/

#ifndef _PEERS_H_
#define _PEERS_H_

#include <time.h>

typedef enum { 
	PEER_STATUS_DEAD,
	PEER_STATUS_INIT,
	PEER_STATUS_READY
} peer_status_t;

typedef struct {
	char * fpr; /* fingerprint */
	char * owner; /* owner udid */
	unsigned int csetmin; 
	unsigned int csetmax;
	time_t lastatime; /* last active time */
	peer_status_t status;
	char * ehost; /* external adress or name */
	unsigned short port;
	unsigned short udcversion; /* should be 1 */
} peer_t;

typedef struct {
	peer_t peer;
	peer_t * next;
} peers_t;

#endif /* _PEERS_H_ */
