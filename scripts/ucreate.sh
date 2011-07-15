#!/bin/bash

SW="OpenUDC - devel"
Version="ucreate.sh 0.0.2 ($SW)"

if [ "$1" == "-V" ] || [ "$1" == "--version" ] ; then 
    echo "$Version"
    exit
elif [ -z "$1" ] || [ "${1:0:1}" == "-" ] ; then
    echo "Usage: $0 CREATION_SET_FILE" >&2
    exit -1
fi

#We have to test that the OpenUDC home contain all the validated cset file (with the network i.e the publication serveur in the first time).
#if ! preuve qu'on est à jour ; then
#   rsync ...
#fi

if ! head -n 1 "$1" | grep "^udcdata=" > /dev/null || ! eval $(gawk ' /^[[:space:]]*idlist=/ { print "nstart="NR+1 ; exit } {print} ' "$1") ; then
    echo "$SW: Error: file \"$1\" is invalid" >&2
    exit -1
fi

if [ "$udcdata" != "cset1.env" ] ; then
    echo "$SW: Sorry, unsupported version ($udcdata)" >&2
    exit -2
fi

if [ -z "$curname" ] || [ -z "$setnum" ] || ((${#factors[*]}!=48)) || [ -z "$dlimc" ] ; then
    echo "$SW: Error: file \"$1\" is invalid" >&2
    exit -1
fi

for ((i=0;i<48;i++)) ; do
    if ((factors[i])) ; then
        ((value+=$(echo $(((48-i)%3?(48-i)%3:5))*10^$(((47-i)/3)) | bc -l )*factors[i]))
    fi
done 

echo -e "\n Set n°$setnum:\n"\
        "\tNumber of Individuals: $idnumber\n"\
        "\tMonetary Dividend: $(echo "scale=2; $value/100" | bc -l ) ${curname}s"

# validation is better outside the creation sheet
#echo -n " Closing date for validation: " 
#if ! date -d "$dlimv" >&2 ; then
#    echo -e "$SW: Error: file \"$1\" is invalid" >&2
#    exit -1
#fi

echo -n " Closing date for creation: " 
if ! date -d "$dlimc" >&2 ; then
    echo -e "$SW: Error: file \"$1\" is invalid" >&2
    exit -1
fi

if (($(date +%s)>$(date -d "$dlimc" +%s))) ; then
    echo "\n Sorry, this set of creation has expired\n" >&2
    exit -2
fi

echo
if gpg2 --version 2> /dev/null | head -n 3 ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null | head -n 3 ; then
    gpg="gpg"
else
    echo -e "\n No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" >&2
    exit -3
fi

mykeys=($($gpg --list-secret-keys --with-colons | grep "^s" | cut -d: -f 5))
# Warning: $mykeys contain non-signing key. It is not really annoying, but it's not clean.

if [ -z "$mykeys" ] ; then 
    echo -e "\n No private key found here. Didn't you forget to create your\n"\
            "OpenPGP certificat or import the private part here ?\n" >&2
    exit -4
fi

myudid2h="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;h;[[:xdigit:]]\{40\};[0-9]\+\)[;)].*,\1,p ')"
#myudid2c="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;c;[A-Z-]\{0,20\};[A-Z-]\{1,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+\)[;)].*,\1,p ')"
myudid2c="$($gpg --list-secret-keys 2> /dev/null | gawk --re-interval '/\(udid2;c;/ { print gensub(/[^(]*\((udid2;c;[A-Z]{1,20};[A-Z-]{1,20};[0-9-]{10};e[0-9.+-]{13};[0-9]+)[;)].*/, "\\1", "1") }' )"
myudid1="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid1;[^);]\+;[^);]\+;[^);]\+;[^);]\+\)[;)].*,\1,p ' | head -n 1 )" 

if ! [ "$myudid2h" -o "$myudid2c" -o "$myudid1" ] ; then 
    echo -e "\n No udid found in your private datas\n"\
            "please create a valid udid2 and make it signed by some confidents contacts\n" >&2
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
    echo -e "\n Sorry, your udid is not in the creation set\n" >&2
    exit
fi

myindex=$((${myline%%:*}-nstart))
mykey="$(echo "$myline" | sed -n ' s,[^"]*"\([[:xdigit:]]\{16\}\);.*,\1,p ')"

echo -e "\nudid=\"$myudid\" key=$mykey position=$myindex"

if ! echo "${mykeys[*]}" | grep "$mykey" > /dev/null ; then
    echo -e "\n Oups ! the keyID associated with your udid ($mykey) is not\n"\
            "one of yours here (${mykeys[*]}).\n"\
            "If there is a mistake in the creation sheet, please alert quickly.\n" >&2
    exit -5
fi

while true ; do
    echo
    read -p "Do you validate this creation set (y/n) ? " rep 
    case "$rep" in
      [yY]*)
        read -t 3 -p "Okay, let's create your part of money !"
        echo -e "\n"
        mkdir -p "$HOME/.openudc/$curname/cset"
        cp -v "$1" "$HOME/.openudc/$curname/cset/cset.$setnum.env"

        #KeyID collision in 2 differents creation sheet time are not managed today
        mkdir -p "$HOME/.openudc/$curname/$mykey"
        cfile="$HOME/.openudc/$curname/$mykey/c.$setnum"
        echo -e "d=t2c\nc=$curname\nh=$(sha1sum -t "$1" | cut -d ' ' -f 1)\nb=(" > "$cfile"
        for ((i=0;i<48;i++)) ; do
            if ((factors[i])) ; then
                value="$(echo $(((48-i)%3?(48-i)%3:5))*10^$(((47-i)/3)) | bc -l )"
                for ((j=0;j<factors[i];j++)) ; do
                    echo -n "$value-$setnum-$((factors[i]*myindex+j)).0 "
                done
                echo
            fi
        done >> "$cfile"
        echo ")" >> "$cfile"
        #$gpg --detach-sign -u "${mykey}!" --armor --output - "$HOME/.openudc/$curname/cset/cset.$setnum.env" >> "$cfile"
        $gpg --sign -u "${mykey}!" "$cfile"
        # Then we havo to publish this creation... and hurry (before dlimc).
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

