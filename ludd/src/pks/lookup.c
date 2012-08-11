/*
 * lookup.c - CGI to lookup keys.
 *
 * Copyright 2002-2005,2007-2009,2011 Jonathan McDowell <noodles@earth.li>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51
 * Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "armor.h"
#include "charfuncs.h"
#include "cleankey.h"
#include "cleanup.h"
#include "getcgi.h"
#include "keydb.h"
#include "keyid.h"
#include "keyindex.h"
#include "log.h"
#include "mem.h"
#include "onak-conf.h"
#include "parsekey.h"
#include "photoid.h"
#include "version.h"

#define OP_UNKNOWN 0
#define OP_GET     1
#define OP_INDEX   2
#define OP_VINDEX  3
#define OP_PHOTO   4
#define OP_HGET    5

#define KEYRING_ALL 7
#define KEYRING_NEW 1
#define KEYRING_VALID 2
#define KEYRING_BLACKLIST 4

#define SERVER_STR "Server: ludd/0.1.0\n"
#define CTYPE_STR "Content-type: text/html\n"
#define QSTRING_MAX 1024

void find_keys(char *search, uint64_t keyid, bool ishex,
		bool fingerprint, bool skshash, bool exact, bool verbose,
		bool mrhkp)
{
	struct openpgp_publickey *publickey = NULL;
	int count = 0;

	if (ishex) {
		count = config.dbbackend->fetch_key(keyid, &publickey, false);
	} else {
		count = config.dbbackend->fetch_key_text(search, &publickey);
	}
	if (publickey != NULL) {
		if (mrhkp) {
			printf("info:1:%d\n", count);
			mrkey_index(publickey);
		} else {
			key_index(publickey, verbose, fingerprint, skshash,
				true);
		}
		free_publickey(publickey);
	} else if (count == 0) {
		if (mrhkp) {
			puts("info:1:0");
		} else {
			puts("Key not found.");
		}
	} else {
		if (mrhkp) {
			puts("info:1:0");
		} else {
			printf("Found %d keys, but maximum number to return"
				" is %d.\n",
				count,
				config.maxkeys);
			puts("Try again with a more specific search.");
		}
	}
}

inline void error_header(int code)
{
	printf("HTTP/1.0 %d OK\n",code);
	printf("%s%s\n",SERVER_STR,CTYPE_STR);
}

int main(int argc, char *argv[])
{
	uint64_t keyid = 0 ;
	char * op=(char *)0;
	char * search=(char *)0;
	char * exact=(char *)0;

	gpgme_ctx_t gpgctx_new;
	gpgme_ctx_t gpgctx_valid;
	gpgme_ctx_t gpgctx_blacklist;
	gpgme_key_t gpgkey;
	gpgme_error_t gpgerr;
	gpgme_engine_info_t enginfo;

	char * qstring=strndup(getenv("QUERY_STRING"),QSTRING_MAX);

	if (! qstring) {
		error_header(500);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: there is no query string.</h1></body></html>");
		return 1;
	}
	pchar=qstring;

	while (pchar && *pchar) {
		if (!strncmp(pchar,"op=",3)) {
			pchar+=3;
			op=pchar;
		} else if (!strncmp(pchar,"search=",7)) {
			pchar+=7;
			search=pchar;
		} else if (!strncmp(pchar,"options=",8)) {
			/*this parameter is useless now, as today we only support "mr" option and always enable it (machine readable) */
			pchar+=8;
			//options=pchar;
		} else if (!strncmp(pchar,"fingerprint=",12)) {
			/*this parameter is useless now as we only support "mr" options which don't care this */
			pchar+=12;
			//fingerprints=pchar;
		} else if (!strncmp(pchar,"exact=",6)) {
			pchar+=6;
			exact=pchar
		} else if (!strncmp(pchar,"x-keyring=",10)) {
			/* this extention may take 4 arguments: "new","valid","blacklist" and "all", default is all */ 
			pchar+=10;
			xkeyring=pchar
		} /*else: Other parameter not in hkp draft are quietly ignored */
		pchar=strchr(pchar,'&');
		if (pchar) {
			*pchar='\0';
			pchar++;
		}
	}

	if (exact) {
		if (!strcmp(exact,"off")) {
			exact=(char *) 0; /* off is default */
		} else if ( strcmp(exact,"on")) {
			error_header(500);
			printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: \"exact\" parameter only take \"on\" or \"off\" as argument.</h1></body></html>");
			return 1;
		}
	}

	if ( ! search ) { 
		/* (mandatory parameter) */
		error_header(500);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: Missing \"search\" parameter in \"%s\".</h1></body></html>",qstring);
		return 1;
	}

	if ( ! op )
		op="index"; /* defaut operation */

	keyring=KEYRING_ALL;
	if (xkeyring) {
		if (!strcmp(xkeyring,"new"))
			keyring=KEYRING_NEW;
		else if (strcmp(xkeyring,"valid"))
			keyring=KEYRING_VALID;
		else if (strcmp(xkeyring,"blacklist"))
			keyring=KEYRING_BLACKLIST;
	}

				

	/* Check gpgme version ( http://www.gnupg.org/documentation/manuals/gpgme/Library-Version-Check.html )*/
	setlocale (LC_ALL, "");
	gpgme_check_version (NULL);
	gpgme_set_locale (NULL, LC_CTYPE, setlocale (LC_CTYPE, NULL));
/*#ifdef LC_MESSAGES
	gpgme_set_locale (NULL, LC_MESSAGES, setlocale (LC_MESSAGES, NULL));
#endif*/
	/* check for OpenPGP support */
	gpgerr=gpgme_engine_check_version(GPGME_PROTOCOL_OpenPGP);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		error_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_engine_check_version).</h1></body></html>");
		return 1;
	}

	gpgerr = gpgme_get_engine_info(&enginfo);

	if (keyring & KEYRING_NEW) {
		/* create context for new keyring*/
		gpgerr=gpgme_new(&gpgctx_new);
		if ( gpgerr  != GPG_ERR_NO_ERROR ) {
			error_header(500);
			printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_new %d).</h1></body></html>",gpgerr);
			return 1;
		}
		gpgerr = gpgme_ctx_set_engine_info(gpgctx_new, GPGME_PROTOCOL_OpenPGP, enginfo->file_name,"../../new");
		if ( gpgerr  != GPG_ERR_NO_ERROR )
			errx(1,"gpgme_ctx_set_engine_info :-( (%d)", gpgerr);

	/* check for an expected secret key */
	gpgerr = gpgme_op_keylist_start(gpgctx, "udbot", 1);
	if ( gpgerr  != GPG_ERR_NO_ERROR )
		errx(1,"gpgme_op_keylist_start :-( (%d)", gpgerr);

	do
		{
		gpgerr = gpgme_op_keylist_next (gpgctx, &gpgkey);

		if ( gpgerr == GPG_ERR_EOF )
			gpgme_key_unref(gpgkey);
		else if ( gpgerr != GPG_ERR_NO_ERROR )
			if (do_init)
				break;
			else
				//errx(1,"there is no private key, forget -init ? (%d)", gpgerr);
				warnx("there is no private key, forget -init ? (%d)", gpgerr); // Just because "-init" is not finished ...
		else if ( gpgkey->revoked )
			warnx("key %s is revoked",gpgkey->uids->uid);
		else if ( gpgkey->expired )
			warnx("key %s is expired",gpgkey->uids->uid);
		else if ( gpgkey->disabled )
			warnx("key %s is disabled",gpgkey->uids->uid);
		else if ( gpgkey->invalid )
			warnx("key %s is invalid",gpgkey->uids->uid);
		else if (! gpgkey->can_sign )
			warnx("key %s can not sign",gpgkey->uids->uid);
		else
			{
			warnx("found key %s",gpgkey->uids->uid);
			//TODO: verify that comment part of uid is expected
			//and warn if not signed by the associated udid in the keyring
			break;
			}

		gpgme_key_unref(gpgkey);
		}
	while (gpgerr == GPG_ERR_NO_ERROR);



	for (i = 0; params != NULL && params[i] != NULL; i += 2) {
		if (!strcmp(params[i], "op")) {
			if (!strcmp(op, "get")) {
				op = OP_GET;
			} else if (!strcmp(op, "hget")) {
				op = OP_HGET;
			} else if (!strcmp(params[i+1], "index")) {
				op = OP_INDEX;
			} else if (!strcmp(params[i+1], "vindex")) {
				error_header(501);
				printf("<html><head><title>Error handling request</title></head><body><h1>Sorry: vindex is not implemented :-/ .</h1></body></html>",qstring);
				return 1;
				op = OP_VINDEX;
			} else if ( !strcmp(params[i+1], "photo") || !strcmp(params[i+1], "x-photo") ) {
				op = OP_PHOTO;
			} else {
				error_header(500);
				printf("HTTP/1.0 500 OK\n");
				printf("%s%s\n",SERVER_STR,CTYPE_STR);
				printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: Unrecognized action in \"%s\".</h1></body></html>",qstring);
				return 1;
			}
		} else if (!strcmp(params[i], "search")) {
			search = params[i+1];
			params[i+1] = NULL;
			if (search != NULL && strlen(search) == 42 &&
					search[0] == '0' && search[1] == 'x') {
				/*
				 * Fingerprint. Truncate to last 64 bits for
				 * now.
				 */
				keyid = strtoull(&search[26], &end, 16);
				if (end != NULL && *end == 0) {
					ishex = true;
				}
			} else if (search != NULL) {
				keyid = strtoull(search, &end, 16);
				if (*search != 0 &&
						end != NULL &&
						*end == 0) {
					ishex = true;
				}
			}
		} else if (!strcmp(params[i], "idx")) {
			indx = atoi(params[i+1]);
		} else if (!strcmp(params[i], "fingerprint")) {
			if (!strcmp(params[i+1], "on")) {
				fingerprint = true;
			}
		} else if (!strcmp(params[i], "hash")) {
			if (!strcmp(params[i+1], "on")) {
				skshash VER_STR,CTYPE_STRERVER_STR,CTYPE_STRERVER_STR,CTYPE_STR                    search[0] == '0' && search[1] == 'x') {
					                    search[0] == '0' && search[1] == 'x') {
											                    search[0] == '0' && search[1] == 'x') {

			}
		} else if (!strcmp(params[i], "exact")) {
			if (!strcmp(params[i+1], "on")) {
				exact = true;
			}
		} else if (!strcmp(params[i], "options")) {
			/*
			 * TODO: We should be smarter about this; options may
			 * have several entries. For now mr is the only valid
			 * one though.
			 */
			if (!strcmp(params[i+1], "mr")) {
				mrhkp = true;
			}
		}
		free(params[i]);
		params[i] = NULL;
		if (params[i+1] != NULL) {
			free(params[i+1]);
			params[i+1] = NULL;
		}
	}
	if (params != NULL) {
		free(params);
		params = NULL;
	}

	if (mrhkp) {
		puts("Content-Type: text/plain\n");
	} else if (op == OP_PHOTO) {
		puts("Content-Type: image/jpeg\n");
	} else {
		start_html("Lookup of key");
	}

	if (op == OP_UNKNOWN) {
		puts("Error: No operation supplied.");
	} else if (search == NULL) {
		puts("Error: No key to search for supplied.");
	} else {
		readconfig(NULL);
		initlogthing("lookup", config.logfile);
		catchsignals();
		config.dbbackend->initdb(false);
		switch (op) {
		case OP_GET:
		case OP_HGET:
			if (op == OP_HGET) {
				parse_skshash(search, &hash);
				result = config.dbbackend->fetch_key_skshash(
					&hash, &publickey);
			} else if (ishex) {
				result = config.dbbackend->fetch_key(keyid,
					&publickey, false);
			} else {
				result = config.dbbackend->fetch_key_text(
					search,
					&publickey);
			}
			if (result) {
				logthing(LOGTHING_NOTICE, 
					"Found %d key(s) for search %s",
					result,
					search);
				puts("<pre>");
				cleankeys(publickey);
				flatten_publickey(publickey,
							&packets,
							&list_end);
				armor_openpgp_stream(stdout_putchar,
						NULL,
						packets);
				puts("</pre>");
			} else {
				logthing(LOGTHING_NOTICE,
					"Failed to find key for search %s",
					search);
				puts("Key not found");
			}
			break;
		case OP_INDEX:
			find_keys(search, keyid, ishex, fingerprint, skshash,
					exact, false, mrhkp);
			break;
		case OP_VINDEX:
			find_keys(search, keyid, ishex, fingerprint, skshash,
					exact, true, mrhkp);
			break;
		case OP_PHOTO:
			if (config.dbbackend->fetch_key(keyid, &publickey,
					false)) {
				unsigned char *photo = NULL;
				size_t         length = 0;

				if (getphoto(publickey, indx, &photo,
						&length)) {
					fwrite(photo,
							1,
							length,
							stdout);
				}
				free_publickey(publickey);
				publickey = NULL;
			}
			break;
		default:
			puts("Unknown operation!");
		}
		config.dbbackend->cleanupdb();
		cleanuplogthing();
		cleanupconfig();
	}
	if (!mrhkp) {
		puts("<hr>");
		puts("Produced by onak " ONAK_VERSION );
		end_html();
	}

	if (search != NULL) {
		free(search);
		search = NULL;
	}
	
	return (EXIT_SUCCESS);
}
