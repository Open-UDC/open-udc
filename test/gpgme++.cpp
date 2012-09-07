#include <gpgme++/data.h>
#include <gpgme++/engineinfo.h>
#include <gpgme.h>
#include <iostream>

using namespace GpgME;

void searchEngine(gpgme_engine_info_t &ei,gpgme_protocol_t p)
{
    EngineInfo result;
    bool foundEngine = false;
    int nbEngine = 0;
    printf("\n");
    for ( gpgme_engine_info_t i = ei ; i ; i = i->next, ++nbEngine )
	{
	    printf("Engine (%d) \n",nbEngine);
	    if ( i->protocol == p )
		{
		    printf("engine info found for %s\n",(p == GPGME_PROTOCOL_OpenPGP) ? "OpenPGP":"CMS");
		    result = EngineInfo( i );
		    foundEngine = true;
		    printf("isNull ? %s\n", result.isNull() ? "true" : "false" );
		    printf("home_dir %s\n", result.homeDirectory());
		    printf("version %s\n", result.version());
		    printf("requiredVersion %s\n",result.requiredVersion());
		    printf("fileName %s\n\n",result.fileName());
		}
	}
    if(!foundEngine)
	{
	    printf("engine info not found for %s\n",(p == GPGME_PROTOCOL_OpenPGP) ? "OpenPGP":"CMS");
	}
}

int main(void)
{
    gpgme_engine_info_t ei = 0;
    if ( gpgme_get_engine_info( &ei ) )
	printf("error not engine info found \n");
    else
	{
	    searchEngine(ei,GPGME_PROTOCOL_OpenPGP);
	    searchEngine(ei,GPGME_PROTOCOL_CMS);
	}
    return 0;
}
