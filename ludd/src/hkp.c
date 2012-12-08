/* hkp.c - hkp management
*
* about HKP please check following urls:
* - http://tools.ietf.org/html/draft-shaw-openpgp-hkp-00
* - http://en.wikipedia.org/wiki/Key_server_%28cryptographic%29
*/

#include <stdlib.h>
#include <syslog.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>   /* errno             */
#include <gpgme.h>
#include <regex.h>
#include <pthread.h>

#include "config.h"
#include "hkp.h"
#include "timers.h"
#include "libhttpd.h"

#define QSTRING_MAX 1024

#ifdef PKS_ADD_LOG
#define PKSADDLOG(...) do { syslog( LOG_INFO,__VA_ARGS__); } while (0)
#else
#define PKSADDLOG(...) while (0)
#endif


/* struct passed to gpgdata4export_cb */
struct gpgdata4export_handle {
	httpd_conn* hc;
	int nsearchs;
	char ** searchs;
}; 


static int export_start=0; /* set to 1 once by gpgdata4export_cb(...) */

#ifdef CHECK_UDID2
extern regex_t udid2c_regex;

/* get first uid in a key where comment match preg
 * \return the uid (or NULL if non found) */
static char * get_matching_comment(const regex_t *preg,const gpgme_key_t gkey) {
	gpgme_user_id_t gpguids;

	if (! preg)
		return((char *) 0);

	gpguids=gkey->uids;
	while (gpguids) {
		if ( !regexec(preg,gpguids->comment, 0, NULL, 0)
				|| !regexec(preg,gpguids->comment+sizeof("ubot1"), 0, NULL, 0) )
			return gpguids->uid;
		gpguids=gpguids->next;
	}
	return((char *) 0);
}
#endif /* CHECK_UDID2 */

int hkp_add( httpd_conn* hc ) {
#define INPUT_MAX (1<<17) /* 1<<17 = 128ko */
	size_t c;
	ssize_t r;

	gpgme_ctx_t gpglctx;
	gpgme_error_t gpgerr;
	gpgme_data_t gpgdata;
	gpgme_import_result_t gpgimport=NULL;
	gpgme_import_status_t gpgikey=NULL;
	gpgme_key_t gpgkey=NULL;
#ifdef CHECK_UDID2 
	char * uid2=NULL;
#endif

	char * buff;
	int buffsize, rcode=200, mergeonly=(hc->hs->bfield & HS_PKS_ADD_MERGE_ONLY);


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


	if (hc->contentlength < 12) {
		httpd_send_err(hc, 411, err411title, "", "Content-Length is absent or too short (%.80s)", "12");
		return(-1);
	}
	if ( hc->contentlength >= INPUT_MAX ) {
		httpd_send_err(hc, 413, err413title, "", "your POST is too big", "");
		return(-1);
	}

	/* To much forks already running */
	if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit ) {
		httpd_send_err(hc, 503, httpd_err503title, "", httpd_err503form,hc->encodedurl );
		return(-1);
	}
	r = fork( );
	if ( r < 0 ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "f" );
		return(-1);
	}
	if ( r > 0 ) {
		/* Parent process. */
		drop_child("hkp",r,hc);
		return(0);
	}
	/* Child process. */
	child_r_start(hc);

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

	if ((gpgimport=gpgme_op_import_result(gpglctx)) == NULL )  {
		httpd_send_err(hc, 500, err500title, "", err500form, "r" );
		exit(EXIT_FAILURE);
	}

	if ( gpgimport->considered == 0 ) {
		httpd_send_err(hc, 400, httpd_err400title, "", httpd_err400form, "" );
		exit(EXIT_FAILURE);
	}

	/* Check (and eventually delete) imported keys */
	gpgikey=gpgimport->imports;
	while (gpgikey) {

		if ( gpgikey->result != GPG_ERR_NO_ERROR ) {
			/* erronous key */
			gpgikey=gpgikey->next;
			continue;
		}
		 /* Is the key new ? */
		if ( gpgikey->status & GPGME_IMPORT_NEW ) {
			/* get the key. */
			if ( (gpgerr=gpgme_get_key (gpglctx,gpgikey->fpr,&gpgkey,0)) != GPG_ERR_NO_ERROR ) {
				/* should not happen */
				httpd_send_err(hc, 500, err500title, "", err500form, "" );
				exit(EXIT_FAILURE);
			}
			if (mergeonly) {
				PKSADDLOG("pks/add:reject:%d:%s:%s:",gpgikey->status,gpgikey->fpr,gpgkey->uids->uid);
				rcode=202;
				gpgerr=gpgme_op_delete(gpglctx,gpgkey,1); /* Note: this also unref the key */
			} else {
#if ! defined CHECK_UDID2
				PKSADDLOG("pks/add:accept:%d:%s:%s:",gpgikey->status,gpgikey->fpr,gpgkey->uids->uid);
#else
				/* Check an uid with comment matching "udid2;c;..." or "ubot1;udid2;c..." */
				uid2=get_matching_comment(&udid2c_regex,gpgkey);
				if (uid2)
					PKSADDLOG("pks/add:accept:%d:%s:%s:",gpgikey->status,gpgikey->fpr,uid2);
				else {
					PKSADDLOG("pks/add:reject:%d:%s:%s:",gpgikey->status,gpgikey->fpr,gpgkey->uids->uid);
					rcode=202;
					gpgerr=gpgme_op_delete(gpglctx,gpgkey,1); /* Note: this also unref the key */
				}
#endif /* CHECK_UDID2 */
			}
			gpgme_key_unref(gpgkey);
		} else
			PKSADDLOG("pks/add:update:%d:%s:",gpgikey->status,gpgikey->fpr);

		gpgikey=gpgikey->next;
	}

	if (rcode==202) {
		send_mime(hc, 202, ok200title, "", "X-HKP-Status: 418 some key(s) was rejected as per keyserver policy\015\012", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
		httpd_write_response(hc);
		r=snprintf(buff,buffsize,"<html><head><title>pks/add ?? keys</title></head><body><h2>%s</h2><h3>It may happen if a keys is unknow or doesn't contain a valid udid2 (\"udid2;c;...\")</h3></body></html>","X-HKP-Status: 418 some key(s) was rejected as per keyserver policy\015\012");
	} else {
		send_mime(hc, 200, ok200title, "", "", "text/html; charset=%s",(off_t) -1, hc->sb.st_mtime );
		httpd_write_response(hc);
		r=snprintf(buff,buffsize,"<html><head><title>pks/add %d keys</title></head><body><h2>Total: %d<br>imported: %d<br>unchanged: %d<br>no_user_id: %d<br>new_user_ids: %d<br>new_sub_keys: %d<br>new_signatures: %d<br>new_revocations: %d<br>secret_read: %d<br>not_imported: %d</h2></body></html>", gpgimport->considered, gpgimport->considered, gpgimport->imported, gpgimport->unchanged, gpgimport->no_user_id, gpgimport->new_user_ids, gpgimport->new_sub_keys, gpgimport->new_signatures, gpgimport->new_revocations, gpgimport->secret_read, gpgimport->not_imported);
	}
	httpd_write_fully( hc->conn_fd, buff,MIN(r,buffsize));

	gpgme_release (gpglctx);
	exit(EXIT_SUCCESS);

	/* TODO:
	 *  Note in memory the fpr in gpgme_import_status_t of all keys imported to :
	 *  - revoke the one with with an usable secret key.
	 *  - propagate them to other ludd key server.
	 * DONE:
	 *  - check if they correspond to our policy (expire less than 20 years after, udid2 must be present ...)
	 */

}

/* callback for gpgme_op_export_ext to write directly the response */
static ssize_t gpgdata4export_cb(struct gpgdata4export_handle * h, void *buffer, size_t size)
{
	if (!export_start) {
		send_mime(h->hc, 200, ok200title, "", "", "text/html; charset=%s",(off_t) -1, h->hc->sb.st_mtime );
		httpd_write_response(h->hc);
		/* dprintf is Posix since 2008 */
		dprintf(h->hc->conn_fd,"<html><head><title>"SOFTWARE_NAME" Public Key Server -- Get: %.80s (%d+)</title></head><body><h1>Public Key Server -- Get: %.80s (%d+)</h1><pre>\n",h->searchs[0],h->nsearchs-1,h->searchs[0],h->nsearchs-1);
		export_start=1;
	}

	return write(h->hc->conn_fd,buffer,size);
}
/* dummy function for callback based gpgme data objects */
static void gpg_data_release_cb(void *handle)
{
	    /* must just be present... bug or feature?!? */
}

/*
 * \return a negative number to finish the connection, or 0 if it have fork.
 */
int hkp_lookup( httpd_conn* hc ) {

#define HKP_MAX_SEARCHS 32
	int r,i,nsearchs=0,p[2];
	char * op=(char *)0;
	char * search[HKP_MAX_SEARCHS+1]={(char *)0};
	char * searchdec[HKP_MAX_SEARCHS+1]={(char *)0};
	char * exact=(char *)0;

	gpgme_ctx_t gpglctx;
	gpgme_error_t gpgerr;

	char * pchar;
	interpose_args_t args;
	pthread_t tparse;
	int terrno=-1;

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
	if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit ) {
		httpd_send_err(hc, 503, httpd_err503title, "", httpd_err503form,hc->encodedurl );
		return(-1);
	}
	r = fork( );
	if ( r < 0 ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "f" );
		return(-1);
	}
	if ( r > 0 ) {
		/* Parent process. */
		drop_child("hkp",r,hc);
		return(0);
	}
	/* Child process. */
	child_r_start(hc);
#define HKP_LOOKUP_EXIT(code) {\
	if (terrno == 0) { \
		close(hc->conn_fd); \
		pthread_join(tparse, NULL); \
	} \
	exit(code); \
}\

	while (pchar && *pchar) {
		if (!strncmp(pchar,"op=",3)) {
			pchar+=3;
			op=pchar;
		} else if (!strncmp(pchar,"search=",7)) {
			pchar+=7;
			if ( *pchar != '\0' && *pchar != '&' ) {
				search[nsearchs]=pchar;
				nsearchs=MIN(HKP_MAX_SEARCHS-1,nsearchs+1);
			}
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
		/* replace the '&' char by EOS */
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

	if ( ! search[0] ) { 
		/* (mandatory parameter) */
		httpd_send_err(hc, 400, httpd_err400title, "", "Missing a \"search\" value in the query.</h1></body></html>","");
		exit(0);
	} else {
		for (i=0;i<nsearchs;i++) {
			if ( (searchdec[i]=malloc(strlen(search[i])*sizeof(char)+1)) ) 
				strdecode(searchdec[i],search[i]);
			else {
				httpd_send_err(hc, 500, err500title, "", err500form, "m" );
				exit(1);
			}
		}
	}

	if ( ! op )
		op="index"; /* defaut operation */

	/* create context */
	gpgerr=gpgme_new(&gpglctx);
	if ( gpgerr  != GPG_ERR_NO_ERROR ) {
		httpd_send_err(hc, 500, err500title, "", err500form, "g01" );
		exit(EXIT_FAILURE);
	}

	if (hc->bfield & HC_DETACH_SIGN) {
		if ( pipe( p ) < 0 ) {
			syslog( LOG_ERR, "pipe - %m" );
			httpd_send_err( hc, 500, err500title, "", err500form, "p" );
			exit(EXIT_FAILURE);
		}
		/* Create a thread for input */
		args.rfd=p[0];
		args.wfd=dup(hc->conn_fd);
		args.hc=hc;
		args.option=1; /* to not caching */

		if (args.wfd < 0) {
			httpd_send_err( hc, 500, err500title, "", err500form, "d" );
			exit(EXIT_FAILURE);
		}
		/* move p[1] to hc->conn_fd */
		if ( dup2(p[1],hc->conn_fd) < 0 ) {
			httpd_send_err( hc, 500, err500title, "", err500form, "d" );
			exit(EXIT_FAILURE);
		}
		close(p[1]);

		terrno=pthread_create(&tparse, NULL,(void * (*)(void *)) &httpd_parse_resp, &args);
		if ( terrno !=0 ) {
			errno=terrno;
			httpd_send_err( hc, 500, err500title, "", err500form, "c" );
			exit(EXIT_FAILURE);
		}
	}
	
	if (!strcmp(op, "get")) {
		gpgme_data_t gpgdata;
		struct gpgme_data_cbs gpgcbs = {
			NULL,									/* read method */
			(gpgme_data_write_cb_t) gpgdata4export_cb,	/* write method */
			NULL,									/* seek method */
			gpg_data_release_cb						/* release method */
		};
		struct gpgdata4export_handle cb_handle = {
			hc,
			nsearchs,
			search
		};
		gpgme_set_armor(gpglctx,1);
		gpgerr = gpgme_data_new_from_cbs(&gpgdata, &gpgcbs,&cb_handle);
		if (gpgerr == GPG_ERR_NO_ERROR) {
			gpgerr = gpgme_data_set_encoding(gpgdata,GPGME_DATA_ENCODING_ARMOR);
		}
		if ( gpgerr != GPG_ERR_NO_ERROR) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g10" );
			HKP_LOOKUP_EXIT(EXIT_FAILURE);
		}
		export_start=0;

		gpgerr = gpgme_op_export_ext(gpglctx,(const char **)searchdec,0,gpgdata);
		if ( gpgerr != GPG_ERR_NO_ERROR) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g11" );
			HKP_LOOKUP_EXIT(EXIT_FAILURE);
		} else if (export_start) {
			write(hc->conn_fd,"\n</pre></body></html>\n",sizeof("\n</pre></body></html>\n")-1);
		} else {
			httpd_send_err(hc, 404, err404title, "", "Get: %.80s (...): No key found ! :-(", search[0]);
		}
		HKP_LOOKUP_EXIT(EXIT_SUCCESS);
	} else if (!strcmp(op, "index")) {
		FILE* fp;
		char begin=0;
		gpgme_key_t gpgkey;
		gpgme_user_id_t gpguid;

		/* Open a stdio stream so that we can use fprintf, which is more
		** efficient than a bunch of separate write()s.  We don't have
		** to worry about double closes or file descriptor leaks cause
		** we're in a subprocess.
		*/
		fp = fdopen( hc->conn_fd, "w" );
		if ( fp == (FILE*) 0 ) {
			httpd_send_err(hc, 500, err500title, "", err500form, "fd" );
			HKP_LOOKUP_EXIT(EXIT_FAILURE);
		}

		/* check for the searched key(s) */
		gpgerr = gpgme_op_keylist_ext_start(gpglctx,(const char **)searchdec, 0, 0);
		//gpgerr = gpgme_op_keylist_start(gpglctx, NULL, 0);
		if ( gpgerr  != GPG_ERR_NO_ERROR ) {
			httpd_send_err(hc, 500, err500title, "", err500form, "g20" );
			HKP_LOOKUP_EXIT(EXIT_FAILURE);
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
			fprintf(fp,"pub:%s:%d:%d:%ld:%ld\n",gpgkey->subkeys->fpr,gpgkey->subkeys->pubkey_algo,gpgkey->subkeys->length,gpgkey->subkeys->timestamp,(gpgkey->subkeys->expires?gpgkey->subkeys->expires:-1));
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
			httpd_send_err(hc, 404, err404title, "", "Get: %.80s (...): No key found ! :-(", search[0]);
			HKP_LOOKUP_EXIT(EXIT_SUCCESS);
		}
		(void) fclose( fp );
		HKP_LOOKUP_EXIT(EXIT_SUCCESS);

	} else if ( !strcmp(op, "photo") || !strcmp(op, "x-photo") ) {
			httpd_send_err(hc, 501, err501title, "", err501form, op );
			HKP_LOOKUP_EXIT(EXIT_FAILURE);
	} else {
		httpd_send_err(hc, 400, httpd_err400title, "", "Unrecognized operation %.80s", op );
		HKP_LOOKUP_EXIT(EXIT_SUCCESS);
	}
}

