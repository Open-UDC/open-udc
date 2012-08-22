/*
 * lookup.c - CGI to lookup keys.
 *
 * Copyright 2012 Jean-Jacques Brucker <open-udc@googlegroups.com>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; version 3 of the License.
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <locale.h>  /* locale support    */
#include <gpgme.h>

#include "version.h"

#define CTYPE_HTML_STR "text/html"
#define QSTRING_MAX 1024
#define BUFFSIZE 1024

static void http_header(int code,const char * ctype)
{
	printf("HTTP/1.0 %d OK\n",code);
	printf("Server: %s\nContent-type: %s\n\n",SERVER_SOFTWARE,(ctype?ctype:CTYPE_HTML_STR));
}

static int hexit( char c ) {
	if ( c >= '0' && c <= '9' )
		return c - '0';
	if ( c >= 'a' && c <= 'f' )
		return c - 'a' + 10;
	if ( c >= 'A' && c <= 'F' )
		return c - 'A' + 10;
	return 0;		   /* shouldn't happen, we're guarded by isxdigit() */
}

/* Copies and decodes a string.  It's ok for from and to to be the
** same string.
*/
static void strdecode( char* to, char* from ) {
	for ( ; *from != '\0'; ++to, ++from ) {
		if ( from[0] == '%' && isxdigit( from[1] ) && isxdigit( from[2] ) ) {
			*to = hexit( from[1] ) * 16 + hexit( from[2] );
			from += 2;
		} else
			*to = *from;
	}
	*to = '\0';
}

/* Copies and encodes a string. */
static void strencode( char* to, int tosize, char* from ) {
	int tolen;

	for ( tolen = 0; *from != '\0' && tolen + 4 < tosize; ++from ) {
		if ( isalnum(*from) || strchr( "/_.-~", *from ) != (char*) 0 ) {
			*to = *from;
			++to;
			++tolen;
		} else {
			(void) sprintf( to, "%%%02x", (int) *from & 0xff );
			to += 3;
			tolen += 3;
		}
	}
	*to = '\0';
}

int main(int argc, char *argv[])
{
	char * op=(char *)0;
	char * search=(char *)0;
	char * searchdec=(char *)0;
	char * exact=(char *)0;

	gpgme_ctx_t gpgctx;
	gpgme_key_t gpgkey;
	gpgme_error_t gpgerr;
	gpgme_engine_info_t enginfo;

	char * qstring, * pchar;

	pchar=getenv("QUERY_STRING");
	if (! pchar || *pchar == '\0' ) {
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: there is no query string.</h1></body></html>");
		return 1;
	}
	qstring=strndup(pchar,QSTRING_MAX); /* copy the QUERY from env to write in */
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
			exact=pchar;
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
		} else if (!strcmp(exact,"on")) {
			http_header(501,CTYPE_HTML_STR);
			printf("<html><head><title>Not implemented</title></head><body><h1>Error handling request: \"exact\" parameter is not implemented.</h1></body></html>");
			return 1;
		} else {
			http_header(500,CTYPE_HTML_STR);
			printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: \"exact\" parameter only take \"on\" or \"off\" as argument.</h1></body></html>");
			return 1;
		}
	}

	if ( ! search ) { 
		/* (mandatory parameter) */
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: Missing \"search\" parameter in \"%s\".</h1></body></html>",getenv("QUERY_STRING"));
		return 1;
	} else {
		if (searchdec=malloc(strlen(search)*sizeof(char)+1)) 
			strdecode(searchdec,search);
		else {
			http_header(500,CTYPE_HTML_STR);
			printf("<html><head><title>Internal Error</title></head><body><h1>Internal malloc(%d) for search fail.</h1></body></html>",strlen(search)*sizeof(char)+1);
			return 1;
		}
	}

	if ( ! op )
		op="index"; /* defaut operation */

	/* Check gpgme version ( http://www.gnupg.org/documentation/manuals/gpgme/Library-Version-Check.html )*/
	setlocale (LC_ALL, "");
	gpgme_check_version (NULL);
	gpgme_set_locale (NULL, LC_CTYPE, setlocale (LC_CTYPE, NULL));
	/* check for OpenPGP support */
	gpgerr=gpgme_engine_check_version(GPGME_PROTOCOL_OpenPGP);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_engine_check_version).</h1></body></html>");
		return 1;
	}

	/* create context */
	gpgerr=gpgme_new(&gpgctx);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_new %d).</h1></body></html>",gpgerr);
		return 1;
	}
	/*gpgerr = gpgme_get_engine_info(&enginfo);
	gpgerr |= gpgme_ctx_set_engine_info(gpgctx, GPGME_PROTOCOL_OpenPGP, enginfo->file_name,"../../new");
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_ctx_set_engine_info %d).</h1></body></html>",gpgerr);
		return 1;
	}*/

	if (!strcmp(op, "get")) {
		gpgme_data_t gpgdata;
		char buff[BUFFSIZE];
		ssize_t read_bytes;

		gpgme_set_armor(gpgctx,1);
		gpgerr = gpgme_data_new(&gpgdata);
		if (gpgerr == GPG_ERR_NO_ERROR) {
			gpgerr = gpgme_data_set_encoding(gpgdata,GPGME_DATA_ENCODING_ARMOR);
			if (gpgerr == GPG_ERR_NO_ERROR)
				gpgerr = gpgme_op_export(gpgctx,searchdec,0,gpgdata);
		}

		if ( gpgerr != GPG_ERR_NO_ERROR) {
			http_header(500,CTYPE_HTML_STR);
			printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (%d).</h1></body></html>",gpgerr);
			return 1;
		}
		gpgme_data_seek (gpgdata, 0, SEEK_SET);
		read_bytes = gpgme_data_read (gpgdata, buff, BUFFSIZE);
		if ( read_bytes == -1 ) {
			http_header(500,CTYPE_HTML_STR);
			printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (%s).</h1></body></html>",gpgme_strerror(errno));
			return 1;
		} else if ( read_bytes <= 0 ) {
			http_header(404,CTYPE_HTML_STR);
			printf("<html><head><title>ludd Public Key Server -- Get: %s</title></head><body><h1>Public Key Server -- Get: %s : No key found ! :-( </h1></body></html>",search,search);
			return 0;
		} else {
			http_header(200,CTYPE_HTML_STR);
			printf("<html><head><title>ludd Public Key Server -- Get: %s</title></head><body><h1>Public Key Server -- Get: %s</h1><pre>",search,search);
			fwrite(buff, sizeof(char),read_bytes,stdout); /* Now it's too late to test fwrite return value ;-) */ 
			while ( (read_bytes = gpgme_data_read (gpgdata, buff, BUFFSIZE)) > 0 )
				fwrite(buff, sizeof(char),read_bytes,stdout);
			printf("\n</pre></body></html>");
			return 0;
		}

	} else if (!strcmp(op, "index")) {
		char uidenc[BUFFSIZE];
		char begin=0;
		gpgme_user_id_t gpguid;

		/* check for the searched key(s) */
		gpgerr = gpgme_op_keylist_start(gpgctx, searchdec, 0);
		//gpgerr = gpgme_op_keylist_start(gpgctx, NULL, 0);
		if ( gpgerr  != GPG_ERR_NO_ERROR ) {
			http_header(500,CTYPE_HTML_STR);
			printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme_op_keylist_start %d).</h1></body></html>",gpgerr);
			return 1;
		}

		gpgerr = gpgme_op_keylist_next (gpgctx, &gpgkey);
		while (gpgerr == GPG_ERR_NO_ERROR) {
			if (!begin) {
				http_header(200,"text/plain");
				begin=1;
				/* Luckily: info "header" is optionnal, see draft-shaw-openpgp-hkp-00.txt */
			}
			/* first subkey is the main key */
			printf("pub:%s:%d:%d:%d:%d\n",gpgkey->subkeys->fpr,gpgkey->subkeys->pubkey_algo,gpgkey->subkeys->length,gpgkey->subkeys->timestamp,(gpgkey->subkeys->expires?gpgkey->subkeys->expires:-1));
			gpguid=gpgkey->uids;
			while (gpguid) {
				printf("uid:%s (%s) <%s>:\n",gpguid->name,gpguid->comment,gpguid->email);
				gpguid=gpguid->next;
			}
			gpgme_key_unref(gpgkey);
			gpgerr = gpgme_op_keylist_next (gpgctx, &gpgkey);
		}
			gpgme_key_unref(gpgkey); /* ... because i don't know how "gpgme_op_keylist_next" behave when not returning GPG_ERR_NO_ERROR */
		if (!begin) {
			http_header(404,CTYPE_HTML_STR);
			printf("<html><head><title>ludd Public Key Server -- index: %s</title></head><body><h1>index Error: No keys found</h1></body></html>",search);
			return 1;
		}
		return 0;

	} else if ( !strcmp(op, "photo") || !strcmp(op, "x-photo") ) {
			http_header(501,CTYPE_HTML_STR);
			printf("<html><head><title>Not implemented</title></head><body><h1>Error handling request: \"%s\" operation is not implemented.</h1></body></html>",op);
			return 1;
	} else {
		http_header(500,CTYPE_HTML_STR);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: Unrecognized action in \"%s\".</h1></body></html>",getenv("QUERY_STRING"));
		return 1;
	}
}

