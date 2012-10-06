/* peers.h - header file for peers management
*/

#ifndef _PEERS_H_
#define _PEERS_H_

#include <time.h>

typedef enum { 
	PEER_STATUS_UNKNOW,
	PEER_STATUS_DEAD,
	PEER_STATUS_INIT,
	PEER_STATUS_READY
} peer_status_t;

typedef struct {
	char kidmin[9];
	char kidmax[9];
} keyidrange_t;

typedef struct {
	unsigned int csetmin; 
	unsigned int csetmax;
} csetrange_t;

typedef struct {
	unsigned short udcversion; /* should be 1 */
	peer_status_t status;
	char * fpr; /* fingerprint */
	time_t lastatime; /* last active time */
	keyidrange_t * akeyrange; /* Authoritative for this key range, a NULL value means that peers disabled "pks/add" */
	csetrange_t * csetrange; /* part of money managed by this peers. A NULL value means that peers only act as key server */
	char * ehost; /* external adress or name */
	unsigned short eport; /* external port */
	char * owner; /* owner udid */
} peer_t;

typedef struct {
	peer_t * peers;
	peer_t * num;
} peers_t;

#endif /* _PEERS_H_ */
