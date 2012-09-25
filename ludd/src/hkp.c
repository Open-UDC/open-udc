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
#define INPUT_MAX (1<<17) /* 1<<17 = 128ko */

/* return this first comment starting with ud found in uids (or NULL if non found) */
static char * get_starting_comment(char * ud, gpgme_key_t gkey) {
	gpgme_user_id_t gpguids;
	size_t n;

	if (! ud)
		return((char *) 0);

	n=strlen(ud);
	gpguids=gkey->uids;
	while (gpguids) {
		if (!strncmp(gpguids->comment,ud,n)) 
			return gpguids->comment;
		gpguids=gpguids->next;
	}
	return((char *) 0);
}

int hkp_add( httpd_conn* hc ) {
	size_t c;
	ssize_t r;
	ClientData client_data;


	gpgme_ctx_t gpglctx;
	gpgme_error_t gpgerr;
	gpgme_data_t gpgdata;
	gpgme_import_result_t gpgimport;
	gpgme_import_status_t gpgikey;
	gpgme_key_t gpgkey;

	char * buff;
	int buffsize, rcode=200;

	if ( hc->method == METHOD_HEAD ) {
		send_mime(
			hc, 200, ok200title, "", "", "text/html; charset=%s", (off_t) -1,
			hc->sb.st_mtime );
		return(-1);
	} else if ( hc->method != METHOD_POST ) {
		httpd_send_err(
			hc, 501, err501title, "", err501form, httpd_method_str( hc->method ) );
		return(-1);
	}


	if (hc->contentlength < 9) {
		httpd_send_err(hc, 411, err411title, "", "Content-Length is absent or to short (%.80s)", "9");
		return(-1);
	}
	if ( hc->contentlength >= INPUT_MAX ) {
		httpd_send_err(hc, 413, err413title, "", "your POST is too big", "");
		return(-1);
	}

	/* To much forks already running */
	if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit )
		{
		httpd_send_err(
			hc, 503, httpd_err503title, "", httpd_err503form,
			hc->encodedurl );
		return(-1);
		}
	++hc->hs->cgi_count;
	r = fork( );
	if ( r < 0 ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "f" );
		return(-1);
	}
	if ( r > 0 ) {
		/* Parent process. */
		syslog( LOG_INFO, "spawned lookup process %d for '%.200s'", r, hc->encodedurl );
#ifdef CGI_TIMELIMIT
		/* Schedule a kill for the child process, in case it runs too long */
		client_data.i = r;
		if ( tmr_create( (struct timeval*) 0, cgi_kill, client_data, CGI_TIMELIMIT * 1000L, 0 ) == (Timer*) 0 )
			{
			syslog( LOG_CRIT, "tmr_create(cgi_kill lookup) failed" );
			/* TODO : It kills the daemon, so maybe kill the Child and return instead of exit */
			exit(EXIT_FAILURE);
			}
#endif /* CGI_TIMELIMIT */
		hc->status = 200;
		hc->bytes_sent = CGI_BYTECOUNT;
		hc->bfield &= ~HC_SHOULD_LINGER;
		return(0);
	}
	/* Child process. */
	sub_process = 1;
	httpd_unlisten( hc->hs );
#ifdef CGI_NICE
	/* Set priority. */
	(void) nice( CGI_NICE );
#endif /* CGI_NICE */

	buffsize=hc->contentlength;
	buff=malloc(buffsize+1);
	if (buff)
		buff[buffsize]='\0'; /*security for strdecode */
	else {
		httpd_send_err(hc, 500, err500title, "", err500form, "m" );
		exit(EXIT_FAILURE);
	}

	c = hc->read_idx - hc->checked_idx;
	if ( c > 0 )
		memcpy(buff,&(hc->read_buf[hc->checked_idx]), c);
	while ( c < hc->contentlength ) {
		r = read( hc->conn_fd, buff+c, hc->contentlength - c );
		if ( r < 0 && ( errno == EINTR || errno == EAGAIN ) )
			{
			struct timespec tim={0, 300000000}; /* 300 ms */
			nanosleep(&tim, NULL);
			//sleep( 1 );
			continue;
			}
		if ( r <= 0 ) {
			httpd_send_err(hc, 500, err500title, "", err500form, "read error" );
			exit(EXIT_FAILURE);
		}
		c += r;
	}

	/* create context */
	gpgerr=gpgme_new(&gpglctx);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		httpd_send_err(hc, 500, err500title, "", err500form, gpgme_strerror(gpgerr) );
		exit(EXIT_FAILURE);
	}

	if (!strncmp(buff,"keytext=",8)) {
		int r;
		r=strdecode(buff,buff+8);
		//gpgme_set_armor(gpglctx,1);
		gpgerr = gpgme_data_new_from_mem(&gpgdata,buff,r,0);
	} else {
		gpgerr = gpgme_data_new_from_mem(&gpgdata,buff,buffsize,0); /* yes: that feature is not in HKP draft */
	}

	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		httpd_send_err(hc, 500, err500title, "", err500form, gpgme_strerror(gpgerr) );
		exit(EXIT_FAILURE);
	}

	if ( (gpgerr=gpgme_op_import (gpglctx, gpgdata)) != GPG_ERR_NO_ERROR ) {
		httpd_send_err(hc, 400, httpd_err400title, "", err500form, gpgme_strerror(gpgerr) );
		exit(EXIT_FAILURE);
	}

	if ((gpgimport= gpgme_op_import_result(gpglctx)) == NULL )  {
		httpd_send_err(hc, 500, err500title, "", err500form, "" );
		exit(EXIT_FAILURE);
	}

	if ( gpgimport->considered == 0 ) {
		httpd_send_err(hc, 400, httpd_err400title, "", httpd_err400form, "" );
		exit(EXIT_FAILURE);
	}

	/* Check (and eventually delete) imported keys */
	gpgikey=gpgimport->imports;
	while (gpgikey) {

		if ( (gpgikey->result != GPG_ERR_NO_ERROR) || (! (gpgikey->status & GPGME_IMPORT_NEW)) ) {
			/* erronous or known key */
			gpgikey=gpgikey->next;
			continue;
		}

		/* key is new, check that it match our policy. */
		if ( (gpgerr=gpgme_get_key (gpglctx,gpgikey->fpr,&gpgkey,0)) != GPG_ERR_NO_ERROR ) {
			/* should not happen */
			httpd_send_err(hc, 500, err500title, "", err500form, "" );
			exit(EXIT_FAILURE);
		}

		/* Check that it does expire and an uid comment start with "udid2;c;" or "udbot1;" */
		if (!( gpgkey->subkeys->expires > 0
				&& (get_starting_comment("udid2;c;",gpgkey)
					|| get_starting_comment("udbot1;",gpgkey)) )) {
			rcode=202;
			gpgme_op_delete (gpglctx,gpgkey,1);
		}
		gpgikey=gpgikey->next;
	}

	if (rcode==202)
		send_mime(hc, 202, ok200title, "", "X-HKP-Status: 418 some key(s) was rejected as per keyserver policy\015\012", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
	else
		send_mime(hc, 200, ok200title, "", "", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
	httpd_write_response(hc);
	r=my_snprintf(buff,buffsize,"<html><head><title>%d keys sended </title></head><body><h2>Total: %d<br>imported: %d<br>unchanged: %d<br>no_user_id: %d<br>new_user_ids: %d<br>new_sub_keys: %d<br>new_signatures: %d<br>new_revocations: %d<br>secret_read: %d<br>not_imported: %d</h2></body></html>", gpgimport->considered, gpgimport->considered, gpgimport->imported, gpgimport->unchanged, gpgimport->no_user_id, gpgimport->new_user_ids, gpgimport->new_sub_keys, gpgimport->new_signatures, gpgimport->new_revocations, gpgimport->secret_read, gpgimport->not_imported);
	httpd_write_fully( hc->conn_fd, buff,MIN(r,buffsize));

	exit(EXIT_SUCCESS);

	/* TODO:
	 *  Note in memory the fpr in gpgme_import_status_t of all keys imported to :
	 *  - clean them (remove previous or useless signatures).  
	 *  - revoke the one with with an usable secret key.
	 *  - propagate them to other ludd key server.
	 * DONE:
	 *  - check if they correspond to our policy (expire less than 20 years after, udid2 must be present ...)
	 */

}

int hkp_repost( httpd_conn* hc ) {
	size_t c;
	ssize_t r;
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
	char buf[BUFFSIZE];

	if ( hc->method == METHOD_HEAD ) {
		send_mime(
			hc, 200, ok200title, "", "", "text/html; charset=%s", (off_t) -1,
			hc->sb.st_mtime );
		return(-1);
	} else if ( hc->method != METHOD_POST ) {
		httpd_send_err(
			hc, 501, err501title, "", err501form, httpd_method_str( hc->method ) );
		return(-1);
	}

			send_mime(hc, 200, ok200title, "", "", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
			httpd_write_response(hc);
	c = hc->read_idx - hc->checked_idx;
	if ( c > 0 )
		{
		if ( httpd_write_fully( hc->conn_fd, &(hc->read_buf[hc->checked_idx]), c ) != c )
			return;
		}
	while ( c < hc->contentlength )
		{
		r = read( hc->conn_fd, buf, MIN( sizeof(buf), hc->contentlength - c ) );
		if ( r < 0 && ( errno == EINTR || errno == EAGAIN ) )
			{
			sleep( 1 );
			continue;
			}
		if ( r <= 0 )
			return;
		if ( httpd_write_fully(hc->conn_fd, buf, r ) != r )
			return;
		c += r;
		}
			httpd_write_response(hc);

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
		return(-1);
	} else if ( hc->method != METHOD_GET ) {
		httpd_send_err(
			hc, 501, err501title, "", err501form, httpd_method_str( hc->method ) );
		return(-1);
	}

	pchar=hc->query;
	if (! pchar || *pchar == '\0' ) {
		httpd_send_err(hc, 400, httpd_err400title, "", "Error handling request: there is no query string", "" );
		return(-1);
	}

	/* To much forks already running */
	if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit )
		{
		httpd_send_err(
			hc, 503, httpd_err503title, "", httpd_err503form,
			hc->encodedurl );
		return(-1);
		}
	++hc->hs->cgi_count;
	r = fork( );
	if ( r < 0 ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "f" );
		return(-1);
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
		hc->bfield &= ~HC_SHOULD_LINGER;
		return(0);
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
			fprintf(fp,"<html><head><title>ludd Public Key Server -- Get: %s</title></head><body><h1>Public Key Server -- Get: %s</h1><pre>\n",search,search);
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

