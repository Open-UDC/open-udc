/* hkp.h - header file for hkp management
*
* about HKP please check following urls:
* - http://tools.ietf.org/html/draft-shaw-openpgp-hkp-00
* - http://en.wikipedia.org/wiki/Key_server_%28cryptographic%29
*/

#include <stdlib.h>
#include <syslog.h>
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

#define GPGBUFFSIZE 2048

int hkp_add( httpd_conn* hc ) {

	struct dirent* de;
	int namlen;
	static int maxnames = 0;
	int nnames;
	static char* names;
	static char** nameptrs;
	static char* name;
	static size_t maxname = 0;
	static char* rname;
	static size_t maxrname = 0;
	static char* encrname;
	static size_t maxencrname = 0;
	FILE* fp;
	int i, r;
	struct stat sb;
	struct stat lsb;
	char modestr[20];
	char* linkprefix;
	char link[MAXPATHLEN+1];
	int linklen;
	char* fileclass;
	time_t now;
	char* timestr;
	ClientData client_data;

	char *p;
	char buf[GPGBUFFSIZE];
	size_t read_bytes;
	int tmp;
	gpgme_ctx_t ceofcontext;
	gpgme_error_t err;
	gpgme_data_t data;

	gpgme_engine_info_t enginfo;

	if ( hc->method == METHOD_HEAD )
		{
		send_mime(
			hc, 200, ok200title, "", "", "text/html; charset=%s", (off_t) -1,
			hc->sb.st_mtime );
		}
	else if ( hc->method == METHOD_GET )
		{
		if ( hc->hs->cgi_limit != 0 && hc->hs->cgi_count >= hc->hs->cgi_limit )
			{
			httpd_send_err(
				hc, 503, httpd_err503title, "", httpd_err503form,
				hc->encodedurl );
			return -1;
			}
		++hc->hs->cgi_count;
		r = fork( );
		if ( r < 0 )
			{
			syslog( LOG_ERR, "fork - %m" );
			httpd_send_err(
				hc, 500, err500title, "", err500form, hc->encodedurl );
			return -1;
			}
		if ( r == 0 )
			{
			/* Child process. */
			sub_process = 1;
			httpd_unlisten( hc->hs );
			send_mime(
				hc, 200, ok200title, "", "", "text/html; charset=%s",
				(off_t) -1, hc->sb.st_mtime );
			httpd_write_response( hc );

#ifdef CGI_NICE
			/* Set priority. */
			(void) nice( CGI_NICE );
#endif /* CGI_NICE */

			/* Open a stdio stream so that we can use fprintf, which is more
			** efficient than a bunch of separate write()s.  We don't have
			** to worry about double closes or file descriptor leaks cause
			** we're in a subprocess.
			*/
			fp = fdopen( hc->conn_fd, "w" );
			if ( fp == (FILE*) 0 )
				{
				syslog( LOG_ERR, "fdopen - %m" );
				httpd_send_err(
					hc, 500, err500title, "", err500form, hc->encodedurl );
				httpd_write_response( hc );
				exit( 1 );
				}

			(void) fprintf( fp, "\
<HTML>\n\
<HEAD><TITLE>Index of %.80s</TITLE></HEAD>\n\
<BODY BGCOLOR=\"#aaccbb\" TEXT=\"#000000\" LINK=\"#2020ff\" VLINK=\"#4040cc\">\n\
<H2>Index of %.80s</H2>\n\
<PRE>\n\
<HR>",
				hc->encodedurl, hc->encodedurl );

   /* get engine information */
   err = gpgme_get_engine_info(&enginfo);
   if(err != GPG_ERR_NO_ERROR) return 2;
   fprintf(fp,"file=%s, home=%s\n",enginfo->file_name,enginfo->home_dir);
   fprintf(fp,"PWD=%s\n",get_current_dir_name());

   /* create our own context */
   err = gpgme_new(&ceofcontext);
   if(err != GPG_ERR_NO_ERROR) return 3;

   /* set protocol to use in our context */
   err = gpgme_set_protocol(ceofcontext,GPGME_PROTOCOL_OpenPGP);
   if(err != GPG_ERR_NO_ERROR) return 4;

   /* set engine info in our context; I changed it for ceof like this:

   err = gpgme_ctx_set_engine_info (ceofcontext, GPGME_PROTOCOL_OpenPGP,
               "/usr/bin/gpg","/home/user/nico/.ceof/gpg/");

      but I'll use standard values for this example: */

   /*err = gpgme_ctx_set_engine_info (ceofcontext, GPGME_PROTOCOL_OpenPGP,
               enginfo->file_name,enginfo->home_dir);*/
   /*err = gpgme_ctx_set_engine_info (ceofcontext, GPGME_PROTOCOL_OpenPGP,
               enginfo->file_name,"."); // "." -> pub dir
   if(err != GPG_ERR_NO_ERROR) return 5;

   /* do ascii armor data, so output is readable in console */
   gpgme_set_armor(ceofcontext, 1);
   
   /* create buffer for data exchange with gpgme*/
   err = gpgme_data_new(&data);
   if(err != GPG_ERR_NO_ERROR) return 6;

   /* set encoding for the buffer... */
   err = gpgme_data_set_encoding(data,GPGME_DATA_ENCODING_ARMOR);
   if(err != GPG_ERR_NO_ERROR) return 7;

   /* verify encoding: not really needed */
   tmp = gpgme_data_get_encoding(data);
   if(tmp == GPGME_DATA_ENCODING_ARMOR) {
      fprintf(fp,"encode ok\n");
   } else {
      fprintf(fp,"encode broken\n");
   }

   /* with NULL it exports all public keys */
   err = gpgme_op_export(ceofcontext,NULL,0,data);
   if(err != GPG_ERR_NO_ERROR) return 8;

   read_bytes = gpgme_data_seek (data, 0, SEEK_END);
   fprintf(fp,"end is=%d\n",read_bytes);
   if(read_bytes == -1) {
      p = (char *) gpgme_strerror(errno);
      fprintf(fp,"data-seek-err: %s\n",p);
      return 9;
   }
   read_bytes = gpgme_data_seek (data, 0, SEEK_SET);
   fprintf(fp,"start is=%d (should be 0)\n",read_bytes);

   fprintf(fp,"\n sizeof... char:%d size_t:%d ssize_t:%d\n",sizeof(char),sizeof(size_t),sizeof(ssize_t));
   /* write keys to stderr */
   while ((read_bytes = gpgme_data_read (data, buf,GPGBUFFSIZE)) > 0) {
      fwrite(buf,sizeof(char),read_bytes,fp);
   }
   /* append \n, so that there is really a line feed */
   fprintf(fp,"\n<br>");

   /* free data */
   gpgme_data_release(data);

   /* free context */
   gpgme_release(ceofcontext);


			(void) fprintf( fp, "</PRE></BODY>\n</HTML>\n" );
			(void) fclose( fp );
			exit( 0 );
			}

		/* Parent process. */
		syslog( LOG_INFO, "spawned indexing process %d for directory '%.200s'", r, hc->expnfilename );
#ifdef CGI_TIMELIMIT
		/* Schedule a kill for the child process, in case it runs too long */
		client_data.i = r;
		if ( tmr_create( (struct timeval*) 0, cgi_kill, client_data, CGI_TIMELIMIT * 1000L, 0 ) == (Timer*) 0 )
			{
			syslog( LOG_CRIT, "tmr_create(cgi_kill ls) failed" );
			exit( 1 );
			}
#endif /* CGI_TIMELIMIT */
		hc->status = 200;
		hc->bytes_sent = CGI_BYTECOUNT;
		hc->should_linger = 0;
		}
	else
		{
		httpd_send_err(
			hc, 501, err501title, "", err501form, httpd_method_str( hc->method ) );
		return -1;
		}

   return 0;
}

int hkp_lookup( httpd_conn* hc ) {
	return -1 ;
}

