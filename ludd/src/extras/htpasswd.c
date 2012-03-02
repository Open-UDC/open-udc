/*
 * htpasswd.c: simple program for manipulating password file for NCSA httpd
 * 
 * Rob McCool
 */

/* Modified 29aug97 by Jef Poskanzer to accept new password on stdin,
** if stdin is a pipe or file.  This is necessary for use from CGI.
*/

#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

extern char *crypt(const char *key, const char *setting);

#define LF 10
#define CR 13

#define CPW_LEN 13

/* ie 'string' + '\0' */
#define MAX_STRING_LEN 256
/* ie 'maxstring' + ':' + cpassword */
#define MAX_LINE_LEN MAX_STRING_LEN+1+CPW_LEN

int tfd;
char temp_template[] = "/tmp/htp.XXXXXX";

void interrupted(int);

static char * strd(char *s) {
    char *d;

    d=(char *)malloc(strlen(s) + 1);
    strcpy(d,s);
    return(d);
}

static void getword(char *word, char *line, char stop) {
    int x = 0,y;

    for(x=0;((line[x]) && (line[x] != stop));x++)
        word[x] = line[x];

    word[x] = '\0';
    if(line[x]) ++x;
    y=0;

    while((line[y++] = line[x++]));
}

static int htgetline(char *s, int n, FILE *f) {
    register int i=0;

    while(1) {
        s[i] = (char)fgetc(f);

        if(s[i] == CR)
            s[i] = fgetc(f);

        if((s[i] == 0x4) || (s[i] == LF) || (i == (n-1))) {
            s[i] = '\0';
            return (feof(f) ? 1 : 0);
        }
        ++i;
    }
}

static void putline(FILE *f,char *l) {
    int x;

    for(x=0;l[x];x++) fputc(l[x],f);
    fputc('\n',f);
}


/* From local_passwd.c (C) Regents of Univ. of California blah blah */
static unsigned char itoa64[] =         /* 0 ... 63 => ascii - 64 */
        "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

static void to64(register char *s, register long v, register int n) {
    while (--n >= 0) {
        *s++ = itoa64[v&0x3f];
        v >>= 6;
    }
}

#ifdef MPE
/* MPE lacks getpass() and a way to suppress stdin echo.  So for now, just
issue the prompt and read the results with echo.  (Ugh). */

char *getpass(const char *prompt) {

static char password[81];

fputs(prompt,stderr);
gets((char *)&password);

if (strlen((char *)&password) > 8) {
  password[8]='\0';
}

return (char *)&password;
}
#endif

static void
add_password( char* user, FILE* f )
    {
    char pass[100];
    char* pw;
    char* cpw;
    char salt[3];

    if ( ! isatty( fileno( stdin ) ) )
	{
	(void) fgets( pass, sizeof(pass), stdin );
	if ( pass[strlen(pass) - 1] == '\n' )
	    pass[strlen(pass) - 1] = '\0';
	pw = pass;
	}
    else
	{
	pw = strd( (char*) getpass( "New password:" ) );
	if ( strcmp( pw, (char*) getpass( "Re-type new password:" ) ) != 0 )
	    {
	    (void) fprintf( stderr, "They don't match, sorry.\n" );
	    if ( tfd != -1 )
		unlink( temp_template );
	    exit( 1 );
	    }
	}
    (void) srandom( (int) time( (time_t*) 0 ) );
    to64( &salt[0], random(), 2 );
    cpw = crypt( pw, salt );
    (void) fprintf( f, "%s:%s\n", user, cpw );
    }

static void usage(void) {
    fprintf(stderr,"Usage: htpasswd [-c] passwordfile username\n"
                   "The -c flag creates a new file.\n"
                   "Will prompt for password, unless given on stdin.\n");
    exit(1);
}

void interrupted(int signo) {
    fprintf(stderr,"Interrupted.\n");
    if(tfd != -1) unlink(temp_template);
    exit(1);
}

int main(int argc, char *argv[]) {
    FILE *tfp,*f;
    char user[MAX_STRING_LEN];
    char line[MAX_LINE_LEN];
    char l[MAX_LINE_LEN];
    char w[MAX_STRING_LEN];
    char command[MAX_STRING_LEN];
    int found,u;

    tfd = -1;
    u = 2; /* argv[u] is username, unless...  */
    signal(SIGINT,(void (*)(int))interrupted);
    if(argc == 4) {
        u = 3;
        if(strcmp(argv[1],"-c"))
            usage();
        if((f=fopen(argv[2],"r")) != NULL) {
          fclose(f);
	  fprintf(stderr,
                "Password file %s already exists.\n"
		"Delete it first, if you really want to overwrite it.\n",
		argv[2]);
	  exit(1);
	}
    } else if(argc != 3) usage();
    /* check uname length; underlying system will take care of pwdfile
       name too long */
    if (strlen(argv[u]) >= MAX_STRING_LEN) {
      fprintf(stderr,"Username too long (max %i): %s\n",
              MAX_STRING_LEN-1, argv[u]);
      exit(1);
    }
    
    if(argc == 4) {
        if(!(tfp = fopen(argv[2],"w"))) {
            fprintf(stderr,"Could not open passwd file %s for writing.\n",
                    argv[2]);
            perror("fopen");
            exit(1);
        }
        printf("Adding password for %s.\n",argv[3]);
        add_password(argv[3],tfp);
        fclose(tfp);
        exit(0);
    }

    if(!(f = fopen(argv[1],"r"))) {
        fprintf(stderr,
                "Could not open passwd file %s for reading.\n",argv[1]);
        fprintf(stderr,"Use -c option to create new one.\n");
        exit(1);
    }
    if(freopen(argv[1],"a",f) == NULL) {
        fprintf(stderr,
                "Could not open passwd file %s for writing!.\n"
		"Changes would be lost.\n",argv[1]);
        exit(1);
    }
    f = freopen(argv[1],"r",f);
    
    /* pwdfile is there, go on with tempfile now ... */
    tfd = mkstemp(temp_template);
    if(!(tfp = fdopen(tfd,"w"))) {
        fprintf(stderr,"Could not open temp file.\n");
        exit(1);
    }
    /* already checked for boflw ... */
    strcpy(user,argv[2]);

    found = 0;
    /* line we get is username:pwd, or possibly any other cruft */
    while(!(htgetline(line,MAX_LINE_LEN,f))) {
        char *i;
	
        if(found || (line[0] == '#') || (!line[0])) {
            putline(tfp,line);
            continue;
        }
	i = index(line,':');
	w[0] = '\0';
	/* actually, cpw is CPW_LEN chars and never null, hence ':' should 
	   always be at line[strlen(line)-CPW_LEN-1] in a valid user:cpw line
	   Here though we may allow for pre-hancrafted pwdfile (!)...
	   But still need to check for length limits.
	 */
	if (i != 0 && i-line <= MAX_STRING_LEN-1) {
          strcpy(l,line);
          getword(w,l,':');
	}
        if(strcmp(user,w)) {
            putline(tfp,line);
            continue;
        }
        else {
            printf("Changing password for user %s\n",user);
            add_password(user,tfp);
            found = 1;
        }
    }
    if(!found) {
        printf("Adding user %s\n",user);
        add_password(user,tfp);
    }
    /* close, rewind & copy */
    fclose(f);
    fclose(tfp);
    f = fopen(argv[1],"w");    
    if(f==NULL) {
      fprintf(stderr,"Failed re-opening %s!?\n",argv[1]);
      exit(1);
    }
    tfp = fopen(temp_template,"r");
    if(tfp==NULL) {
      fprintf(stderr,"Failed re-opening tempfile!?\n");
      exit(1);
    }
    {
      int c;
      while((c=fgetc(tfp))!=EOF && !feof(tfp))  {
        fputc(c,f);
        /* fputc(c,stderr); */
      }
    }
    fclose(f);
    fclose(tfp);
    unlink(temp_template);
    exit(0);
}
