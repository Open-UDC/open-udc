/* hkp.h - header file for hkp management
*
* about HKP please check following urls:
* - http://tools.ietf.org/html/draft-shaw-openpgp-hkp-00
* - http://en.wikipedia.org/wiki/Key_server_%28cryptographic%29
*/

#include <stdlib.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>   /* errno             */
#include <locale.h>  /* locale support    */
#include <gpgme.h>

#include "hkp.h"
#include "timers.h"
#include "libhttpd.h"

#ifdef CGI_TIMELIMIT
extern void cgi_kill(ClientData client_data, struct timeval* nowP );
#endif /* CGI_TIMELIMIT */

/* This global keeps track of whether we are in the main process or a
** sub-process.  The reason is that httpd_write_response() can get called
** in either context; when it is called from the main process it must use
** non-blocking I/O to avoid stalling the server, but when it is called
** from a sub-process it wants to use blocking I/O so that the whole
** response definitely gets written.  So, it checks this variable.  A bit
** of a hack but it seems to do the right thing.
*/
extern int sub_process;

#define QSTRING_MAX 1024
#define BUFFSIZE 2048

/* TODO: move pks/add from cgi script to here to increase perf */
int hkp_add( httpd_conn* hc ) {
   return(-1);
}

int hkp_lookup( httpd_conn* hc ) {

	int r;
	FILE* fp;
	ClientData client_data;

	char * op=(char *)0;
	char * search=(char *)0;
	char * searchdec=(char *)0;
	char * exact=(char *)0;

	gpgme_ctx_t gpglctx;
	gpgme_key_t gpgkey;
	gpgme_error_t gpgerr;

	char * qstring, * pchar;

	if ( hc->method == METHOD_HEAD ) {
		send_mime(
			hc, 200, ok200title, "", "", "text/html; charset=%s", (off_t) -1,
			hc->sb.st_mtime );
		return 0;
	} else if ( hc->method =! METHOD_GET ) {
		httpd_send_err(
			hc, 501, err501title, "", err501form, httpd_method_str( hc->method ) );
		return -1;
	}

	pchar=hc->query;
	if (! pchar || *pchar == '\0' ) {
		httpd_send_err(hc, 400, httpd_err400title, "", "Error handling request: there is no query string", "" );
		return 1;
	}

	if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit )
		{
		httpd_send_err(
			hc, 503, httpd_err503title, "", httpd_err503form,
			hc->encodedurl );
		return -1;
		}
	++hc->hs->cgi_count;
	r = fork( );
	if ( r < 0 ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "f" );
		return -1;
	}
	if ( r > 0 ) {
		/* Parent process. */
		syslog( LOG_INFO, "spawned lookup process %d for '%.200s'", r, hc->query );
#ifdef CGI_TIMELIMIT
		/* Schedule a kill for the child process, in case it runs too long */
		client_data.i = r;
		if ( tmr_create( (struct timeval*) 0, cgi_kill, client_data, CGI_TIMELIMIT * 1000L, 0 ) == (Timer*) 0 )
			{
			syslog( LOG_CRIT, "tmr_create(cgi_kill lookup) failed" );
			/* TODO : It kills the daemon, so maybe kill the Child and return instead of exit */
			exit( 1 );
			}
#endif /* CGI_TIMELIMIT */
		hc->status = 200;
		hc->bytes_sent = CGI_BYTECOUNT;
		hc->hmask &= ~HC_SHOULD_LINGER;
		return 0;
	}
	/* Child process. */
	sub_process = 1;
	httpd_unlisten( hc->hs );
#ifdef CGI_NICE
	/* Set priority. */
	(void) nice( CGI_NICE );
#endif /* CGI_NICE */

	qstring=strndup(pchar,QSTRING_MAX); /* copy the QUERY to write in */
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
			httpd_send_err(hc, 501, err501title, "", err501form, "exact=on" );
			exit(1);
		} else {
			httpd_send_err(hc, 400, httpd_err400title, "", "\"exact\" parameter only take \"on\" or \"off\" as argument.", "" );
			exit(0);
		}
	}

	if ( ! search ) { 
		/* (mandatory parameter) */
		httpd_send_err(hc, 400, httpd_err400title, "", "Missing \"search\" parameter in \"%.80s\".</h1></body></html>", hc->query );
		exit(0);
	} else {
		if (searchdec=malloc(strlen(search)*sizeof(char)+1)) 
			strdecode(searchdec,search);
		else {
			httpd_send_err(hc, 500, err500title, "", err500form, "m" );
			exit(1);
		}
	}

	if ( ! op )
		op="index"; /* defaut operation */

	/* create context */
	gpgerr=gpgme_new(&gpglctx);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "g01" );
		exit(1);
	}
	

	/* Open a stdio stream so that we can use fprintf, which is more
	** efficient than a bunch of separate write()s.  We don't have
	** to worry about double closes or file descriptor leaks cause
	** we're in a subprocess.
	*/
	fp = fdopen( hc->conn_fd, "w" );
	if ( fp == (FILE*) 0 )
		{
		httpd_send_err(hc, 500, err500title, "", err500form, "fd" );
		exit(1);
		}

	if (!strcmp(op, "get")) {
		gpgme_data_t gpgdata;
		char buff[BUFFSIZE];
		ssize_t read_bytes;

		gpgme_set_armor(gpglctx,1);
		gpgerr = gpgme_data_new(&gpgdata);
		if (gpgerr == GPG_ERR_NO_ERROR) {
			gpgerr = gpgme_data_set_encoding(gpgdata,GPGME_DATA_ENCODING_ARMOR);
			if (gpgerr == GPG_ERR_NO_ERROR)
				gpgerr = gpgme_op_export(gpglctx,searchdec,0,gpgdata);
		}

		if ( gpgerr != GPG_ERR_NO_ERROR) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g10" );
			exit(1);
		}
		gpgme_data_seek (gpgdata, 0, SEEK_SET);
		read_bytes = gpgme_data_read (gpgdata, buff, BUFFSIZE);
		if ( read_bytes == -1 ) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g11" );
			exit(1);
		} else if ( read_bytes <= 0 ) {
			httpd_send_err(hc, 404, err404title, "", "Get: %.80s : No key found ! :-(", search );
			exit(0);
		} else {
			send_mime(hc, 200, ok200title, "", "", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
			httpd_write_response(hc);
			fprintf(fp,"<html><head><title>ludd Public Key Server -- Get: %s</title></head><body><h1>Public Key Server -- Get: %s</h1><pre>",search,search);
			fwrite(buff, sizeof(char),read_bytes,fp); /* Now it's too late to test fwrite return value ;-) */ 
			while ( (read_bytes = gpgme_data_read (gpgdata, buff, BUFFSIZE)) > 0 )
				fwrite(buff, sizeof(char),read_bytes,fp);
			fprintf(fp,"\n</pre></body></html>");
			(void) fclose( fp );
			exit(0);
		}
	} else if (!strcmp(op, "index")) {
		char uidenc[BUFFSIZE];
		char begin=0;
		gpgme_user_id_t gpguid;

		/* check for the searched key(s) */
		gpgerr = gpgme_op_keylist_start(gpglctx, searchdec, 0);
		//gpgerr = gpgme_op_keylist_start(gpglctx, NULL, 0);
		if ( gpgerr  != GPG_ERR_NO_ERROR ) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g20" );
			exit(1);
		}

		gpgerr = gpgme_op_keylist_next (gpglctx, &gpgkey);
		while (gpgerr == GPG_ERR_NO_ERROR) {
			if (!begin) {
				send_mime(hc, 200, ok200title, "", "", "text/plain; charset=%s",(off_t) -1, hc->sb.st_mtime );
				httpd_write_response(hc);
				begin=1;
				/* Luckily: info "header" is optionnal, see draft-shaw-openpgp-hkp-00.txt */
			}
			/* first subkey is the main key */
			fprintf(fp,"pub:%s:%d:%d:%d:%d\n",gpgkey->subkeys->fpr,gpgkey->subkeys->pubkey_algo,gpgkey->subkeys->length,gpgkey->subkeys->timestamp,(gpgkey->subkeys->expires?gpgkey->subkeys->expires:-1));
			gpguid=gpgkey->uids;
			while (gpguid) {
				fprintf(fp,"uid:%s (%s) <%s>:\n",gpguid->name,gpguid->comment,gpguid->email);
				gpguid=gpguid->next;
			}
			gpgme_key_unref(gpgkey);
			gpgerr = gpgme_op_keylist_next (gpglctx, &gpgkey);
		}
			gpgme_key_unref(gpgkey); /* ... because i don't know how "gpgme_op_keylist_next" behave when not returning GPG_ERR_NO_ERROR */
		if (!begin) {
			httpd_send_err(hc, 404, err404title, "", "Get: %.80s : No key found ! :-(", search );
			exit(0);
		}
		(void) fclose( fp );
		exit(0);

	} else if ( !strcmp(op, "photo") || !strcmp(op, "x-photo") ) {
			httpd_send_err(hc, 501, err501title, "", err501form, op );
			exit(1);
	} else {
		httpd_send_err(hc, 400, httpd_err400title, "", "Unrecognized operation %.80s", op );
		exit(0);
	}
	exit(-1) ;
}

