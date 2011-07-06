#!/bin/bash

if [ "${1:0:1}" == "-" ] || ! source "$1" ; then
    echo "Usage: $0 CREATION_SET_FILE" >&2
    exit -2
fi

if [ "$udcdata" != "cset1.env" ] ; then
    echo "Sorry, unsupported version ($udcdata)" >&2
    exit -3
fi

if gpg2 --version 2> /dev/null ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null ; then
    gpg="gpg"
else
    echo -e "no gpg found in your \$PATH ($PATH)\n"
            "please install GnuPG (http://www.gnupg.org/)"
    exit -1
fi

mykeys=($(gpg2 --list-secret-keys --with-colons | grep "^s" | cut -d: -f 5))

if gpg2 --list-secret-keys 2> /dev/null | grep -o "udid2;h;[[:xdigit:]]\{,40\};[0-9]\+;" ; then 
    myudid=$(gpg2 --list-secret-keys 2> /dev/null | grep -o -m 1 "udid2;h;[[:xdigit:]]\{,40\};[0-9]\+;")
elif gpg2 --list-secret-keys 2> /dev/null | grep -o "udid2;c;[A-Z-]\{,20\};[A-Z-]\{,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+;" ; then 
    myudid=$(gpg2 --list-secret-keys 2> /dev/null | grep -o -m 1 "udid2;c;[A-Z-]\{,20\};[A-Z-]\{,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+;")
elif gpg2 --list-secret-keys 2> /dev/null | grep -o "udid1;[^;]\+;[^;]\+;[^;]\+;[^;]\+;" ; then
    myudid=$(gpg2 --list-secret-keys 2> /dev/null | grep -o -m 1 "udid1;[^;]\+;[^;]\+;[^;]\+;[^;]\+;")
else
    echo -e "no udid found in your private datas\n"
            "please create a valid udid2 and make it signed by some confidents contacts"
    exit -2
fi


