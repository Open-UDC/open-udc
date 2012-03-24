/* hkp.h - header file for hkp management
*
* about HKP please check following urls:
* - http://tools.ietf.org/html/draft-shaw-openpgp-hkp-00
* - http://en.wikipedia.org/wiki/Key_server_%28cryptographic%29
*/

#ifndef _HKP_H_
#define _HKP_H_

#include "config.h"
#include "libhttpd.h"

/*! hkp_add permit to add a new public key on the validation node.
 * ludd first checks if keys in certificates don't already exist in its keyrings,
 * then it checks that the udid is sufficiently signed by recent keys,
 * then it checks there is a key fingerprint with udid is in a creation list,
 * then it cleans the certificate to remove all unknow key (not in creation sheet) and all unknows signatures (from unknows keys).
 * \return 0 (always fork)
 */
int hkp_add( httpd_conn* hc );

/*! hkp_lookup permit to get a public certificate from the validation node.
 * \return -1 if parameter are inconsistant, or 0 (fork).
 */
int hkp_lookup( httpd_conn* hc );

#endif /* _HKP_H_ */
