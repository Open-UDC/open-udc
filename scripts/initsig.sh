#!/bin/bash

if [ "${1:0:1}" == "-" ] || ! head -n 1 "$1" | grep "^udcdata=" > /dev/null ; then
    echo "Usage: $0 CREATION_SET_FILE" >&2
    exit -1
fi

if ! eval $(gawk ' /^[[:space:]]*idlist=/ { print "nstart="NR+1 ; exit } {print} ' mmass/uni/cset.1.env) ; then
    echo "Error: file \"$1\" is invalid" >&2
    exit -1
fi

if [ "$udcdata" != "cset1.env" ] ; then
    echo "Sorry, unsupported version ($udcdata)" >&2
    exit -2
fi

if gpg2 --version 2> /dev/null | head -n 3 ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null | head -n 3 ; then
    gpg="gpg"
else
    echo -e " No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)" >&2
    exit -3
fi


mykeys=($($gpg --list-secret-keys --with-colons | grep "^s" | cut -d: -f 5))
# Warning: $mykeys contain non-signing key. It is not really annoying, but it's not clean.

if [ -z "$mykeys" ] ; then 
    echo -e " No private key found here. Didn't you forget to create your\n"\
            "OpenPGP certificat or import the private part here ?" >&2
    exit -4
fi

echo myudid2h="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;h;[[:xdigit:]]\{40\};[0-9]\+\)[;)].*,\1,p ')"
#myudid2c="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;c;[A-Z-]\{0,20\};[A-Z-]\{1,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+\)[;)].*,\1,p ')"
echo myudid2c="$($gpg --list-secret-keys 2> /dev/null | gawk --re-interval '/\(udid2;c;/ { print gensub(/[^(]*\((udid2;c;[A-Z-]{0,20};[A-Z-]{1,20};[0-9-]{10};e[0-9.+-]{13};[0-9]+)[;)].*/, "\\1", "1") }' )"
echo myudid1="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid1;[^);]\+;[^);]\+;[^);]\+;[^);]\+\)[;)].*,\1,p ' | head -n 1 )" 

if ! [ "$myudid2h" -o "$myudid2c" -o "$myudid1" ] ; then 
    echo -e " No udid found in your private datas\n"\
            "please create a valid udid2 and make it signed by some confidents contacts" >&2
    exit -4
fi

#myudid="$(([ "$myudid2h" ] && grep -o "$myudid2h" $1 ) || ([ "$myudid2c" ] && grep -o "$myudid2c" $1 ) || ([ "$myudid1" ] && grep -o "$myudid1" $1 ))"
if [ "$myudid2h" ] && myline="$(grep -n "$myudid2h\"" $1 )" ; then
    myudid="$myudid2h"
elif [ "$myudid2c" ] && myline="$(grep -n "$myudid2c\"" $1 )" ; then
    myudid="$myudid2c"
elif [ "$myudid1" ] && myline="$(grep -n "$myudid1\"" $1 )" ; then
    myudid="$myudid1"
else
    echo "Sorry, your udid is not in the creation set" >&2
    exit
fi
myindex=$((${myline%%:*}-nstart))
mykey="$(echo "$myline" | sed -n ' s,[^"]*"\([[:xdigit:]]\{16\}\);.*,\1,p ')"

if ! echo "${mykeys[*]}" | grep "$mykey" > /dev/null ; then
    echo -e " Oups ! the keyID associated with your udid ($mykey) is not\n"\
            "one of yours here (${mykeys[*]}).\n"\
            "If there is a mistake in the creation sheet, please alert quickly." >&2
    exit -5
fi

while true ; do
    read -p "Have you read the new creation sheet (y/n) ? " rep
    case "$rep" in
      [yY]*)
        echo -n "^^ "
        break
        ;;
      [nN]*)
        read -t 5 -p "So it will be displayed now, press q when you're done."
        echo
        less "$1" || more "$1"
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
        read -t 3 -p "Okay, let's create your part of money !"
        mkdir -p "$HOME/.openudc/$curname/cset"
        #if 
        mkdir -p "$HOME/.openudc/$curname/$mykey"
        cp -v "$1" "$HOME/.openudc/$curname/cset/"
        $gpg --detach-sign -u "${mykey}!" --armor --output - $1 
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

## (check if the file

