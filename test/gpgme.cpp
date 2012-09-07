#include <gpgme.h>
#include <iostream>

int main(void)
{
    std::cout << "GPGME Protocol OpenPGP: "
	      << gpgme_strerror( gpgme_engine_check_version( GPGME_PROTOCOL_OpenPGP ) )
	      << std::endl;

    return 0;
}
