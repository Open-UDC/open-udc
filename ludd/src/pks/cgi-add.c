/*
 * cgi-add.c - CGI to add keys to a keyring, according to OpenUDC policy.
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
#include <locale.h>  /* locale support    */
#include <gpgme.h>

#include "version.h"

#define INPUT_MAX (1<<16) /* 1<<16 = 64ko */

static void http_header(int code)
{
	printf("HTTP/1.0 %d OK\n",code);
	//printf("X-HKP-Status: 418 Submitted key was rejected as per keyserver policy\n");
	printf("Server: %s\nContent-type: text/html\n\n",SERVER_SOFTWARE);

}

static int hexit( char c ) {
	if ( c >= '0' && c <= '9' )
		return c - '0';
	if ( c >= 'a' && c <= 'f' )
		return c - 'a' + 10;
	if ( c >= 'A' && c <= 'F' )
		return c - 'A' + 10;
	return -1;	
}

/* Copies and decodes a string.  It's ok for from and to to be the
** same string. Return the lenght of decoded string.
*/
static int strdecode( char* to, char* from ) {
	int a,b,r;
	for ( r=0 ; *from != '\0'; to++, from++, r++ ) {
		if ( from[0] == '%' && (a=hexit(from[1])) >= 0 && (b=hexit(from[2])) >= 0 ) {
			*to = a* 16 + b;
			from += 2;
		} else
			*to = *from;
	}
	*to = '\0';
	return r;
}

int main(int argc, char *argv[])
{
	gpgme_ctx_t gpgctx;
	gpgme_error_t gpgerr;
	//gpgme_engine_info_t enginfo;
	gpgme_data_t gpgdata;
	gpgme_import_result_t gpgimport;

	char * pclen, * buff;
	int clen;

	pclen=getenv("CONTENT_LENGTH");
	if (! pclen || *pclen == '\0' || (clen=atoi(pclen)) < 9 ) {
		http_header(411);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: Only non-empty POST containing OpenPGP certificate(s) compatible with an OpenUDC Policy are accepted here !</h1></body></html>");
		return 1;
	}

	if ( clen >= INPUT_MAX ) {
		http_header(413);
		printf("<html><head><title>Error handling request</title></head><body><h1>Error handling request: your POST is too big.</h1></body></html>");
		return 1;
	}

	buff=malloc(clen+1);
	if (buff)
		buff[clen]='\0'; /*security for strdecode */
	else {
		http_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Internal Error.</h1></body></html>");
		return 1;
	}

	if ( fread(buff,sizeof(char),clen,stdin) != clen ) {
		http_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error reading your data.</h1></body></html>");
		return 1;
	}

	/* Check gpgme version ( http://www.gnupg.org/documentation/manuals/gpgme/Library-Version-Check.html )*/
	setlocale (LC_ALL, "");
	gpgme_check_version (NULL);
	gpgme_set_locale (NULL, LC_CTYPE, setlocale (LC_CTYPE, NULL));
	/* check for OpenPGP support and create context */
	gpgerr=gpgme_engine_check_version(GPGME_PROTOCOL_OpenPGP);
	if (gpgerr == GPG_ERR_NO_ERROR)
		gpgerr=gpgme_new(&gpgctx);
	/*if (gpgerr == GPG_ERR_NO_ERROR)
		gpgerr = gpgme_get_engine_info(&enginfo);
	if (gpgerr == GPG_ERR_NO_ERROR)
		gpgerr = gpgme_ctx_set_engine_info(gpgctx, GPGME_PROTOCOL_OpenPGP, enginfo->file_name,TMP_DIR);
	*/

	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		http_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Error handling request due to internal error (gpgme %d).</h1></body></html>",gpgerr);
		return 1;
	}

	if (!strncmp(buff,"keytext=",8)) {
		int r;
		r=strdecode(buff,buff+8);
		//gpgme_set_armor(gpgctx,1);
		gpgerr = gpgme_data_new_from_mem(&gpgdata,buff,r,0);
	} else {
		gpgerr = gpgme_data_new_from_mem(&gpgdata,buff,clen,0); /* yes: that feature is not in HKP draft */
	}

	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		http_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Internal Error (%d).</h1></body></html>",gpgerr);
		return 1;
	}

	if ( (gpgerr=gpgme_op_import (gpgctx, gpgdata)) != GPG_ERR_NO_ERROR ) {
		http_header(400);
		printf("<html><head><title>Error</title></head><body><h1>Error handling request (gpgme import %d).</h1></body></html>",gpgerr);
		return 1;
	}

	if ((gpgimport= gpgme_op_import_result(gpgctx)) == NULL )  {
		http_header(500);
		printf("<html><head><title>Internal Error</title></head><body><h1>Internal Error result is NULL (... should not happen :-/).</h1></body></html>");
		return 1;
	}

	if ( gpgimport->considered == 0 ) {
		http_header(400);
		printf("<html><head><title>Error</title></head><body><h1>Error handling request (No valid key POST).</h1></body></html>",gpgerr);
		return 1;
	}

	http_header(200);
	printf("<html><head><title>%d keys sended </title></head><body><h2>Total: %d<br>imported: %d<br>unchanged: %d<br>no_user_id: %d<br>new_user_ids: %d<br>new_sub_keys: %d<br>new_signatures: %d<br>new_revocations: %d<br>secret_read: %d<br>not_imported: %d</h2></body></html>", gpgimport->considered, gpgimport->considered, gpgimport->imported, gpgimport->unchanged, gpgimport->no_user_id, gpgimport->new_user_ids, gpgimport->new_sub_keys, gpgimport->new_signatures, gpgimport->new_revocations, gpgimport->secret_read, gpgimport->not_imported);
	return 0;

	/*TODO:
	 * Note in memory the fpr in gpgme_import_status_t of all keys imported to :
	 *  - check if they correspond to our policy (expire less than 20 years after, udid2 must be present ...)
	 *  - clean them (remove previous or useless signatures).  
	 *  - revoke the one with with an usable secret key.
	 *  - propagate them to other ludd key server.
	 */

}

