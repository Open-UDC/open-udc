#!/bin/bash

if [ "${1:0:1}" == "-" ] || ! source "$1" ; then
    echo "Usage: $0 CREATION_SET_FILE" >&2
    exit -1
fi

if [ "$udcdata" != "cset1.env" ] ; then
    echo "Sorry, unsupported version ($udcdata)" >&2
    exit -2
fi

if gpg2 --version 2> /dev/null ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null ; then
    gpg="gpg"
else
    echo -e "no gpg found in your \$PATH ($PATH)\n"
            "please install GnuPG (http://www.gnupg.org/)"
    exit -3
fi

mykeys=($(gpg2 --list-secret-keys --with-colons | grep "^s" | cut -d: -f 5))

myudid2h="$(gpg2 --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;h;[[:xdigit:]]\{40\};[0-9]\+\)[;)].*,\1,p ')"
#myudid2c="$(gpg2 --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;c;[A-Z-]\{0,20\};[A-Z-]\{1,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+\)[;)].*,\1,p ')"
myudid2c="$(gpg2 --list-secret-keys 2> /dev/null | gawk '/udid2;c/ { print gensub(/.*(\(udid2;c;[A-Z-]\{0,20\};[A-Z-]\{1,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+)[;)].*/, "\\1", "1") }' )"
myudid1="$(gpg2 --list-secret-keys 2> /dev/null | grep -o "udid1;[^;]\+;[^;]\+;[^;]\+;[^;]\+;" | head -n 1 )" 
echo $myudid1
if ! [ "$myudid2h" -o "$myudid2c" -o "$myudid1" ] ; then 
    echo -e "no udid found in your private datas\n"
            "please create a valid udid2 and make it signed by some confidents contacts"
    exit -4
fi

if grep "\($myudid2h\|$myudid2c\|$myudid1\)" $1 ; then
    while true ; do
        read -p "Have you read the new creation sheet (y/n) ? " rep
        case "$rep" in
          [yY]*)
            echo -n "^^ "
            break
            ;;
          [nN]*)
            less $1
            break
            ;;
          *)
            echo "  please answer \"yes\" or \"no\""
            ;;
        esac
    done
    while true ; do
        read -p "Do you validate this creation set (y/n) ? " rep 
        case "$rep" in
          [yY]*)
            echo -n "^^ "
            break
            ;;
          [nN]*)
            echo "Okay. If you have not already, please express (to the community) why you disagree."
            break
            ;;
          *)
            echo "  please answer \"yes\" or \"no\""
            ;;
        esac
    done
else 
    echo "Sorry, your udid is not in the creation set"
    exit
fi


            
            

## (check if the file
