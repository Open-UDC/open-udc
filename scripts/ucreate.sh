#!/bin/bash

SW="OpenUDC - devel"
Version="ucreate.sh 0.0.2 ($SW)"
SHome="$HOME/.openudc"

if [ "$1" == "-V" ] || [ "$1" == "--version" ] ; then 
    echo "$Version"
    exit
elif [ "${1:0:1}" == "-" ] ; then
    echo "Usage: $0 [CREATION_SHEET]" >&2
    exit -1
fi




if [ -z "$1" ] ; then
    # TO DO : use a config file or ~/.openudc/config
    PubServList=("https://github.com/jbar/open-udc/tree/master/data")
    DefCurrency="uni"
    TMPDIR="/tmp"

    echo "Sorry, works to auto-synchronize creation with publications servers is still in progress..." >&2
    echo "Usage: $0 [CREATION_SHEET]" >&2
    exit


    if curl "${PubServList[0]}/$DefCurrency/c/cset.status" > "$TMPDIR/cset.status" \
        || wget -O - "${PubServList[0]}/$DefCurrency/c/cset.status" > "$TMPDIR/cset.status" \
        || GET "${PubServList[0]}/$DefCurrency/c/cset.status" > "$TMPDIR/cset.status" ; then
        if diff "$SHome/$DefCurrency/c/cset.status" "$TMPDIR/cset.status" ; then
            echo "Nothing to do: You are synchronized with the published creations !"
            exit
        else
            # get the missing sheets
            echo
            # ...
        fi
    else
        echo " Error: unable to retrieve creation status from publication server(s)" ; exit -4
    fi
fi

#We have to test that the OpenUDC home contain all the validated cset file (with the network i.e the publication serveur in the first time).
#if ! preuve qu'on est à jour ; then
#   rsync ...
#fi

if ! head -n 1 "$1" | grep "^udcdata=" > /dev/null || ! eval $(gawk ' /^[[:space:]]*d=idlist\>/ { print "nstart="NR ; exit } {print} ' "$1") ; then
    echo "$SW: Error: file \"$1\" is invalid" >&2
    exit -1
fi

if [ "$udcdata" != "cset2.env" ] ; then
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

# Note: validation process is something external to the creation sheet.

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
if gpg2 --version > /dev/null 2>&1 ; then 
    gpg="gpg2"
elif gpg --version > /dev/null 2>&1 ; then
    gpg="gpg"
else
    echo -e "\n No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" >&2
    exit -3
fi

mykeys=($($gpg --list-secret-keys --with-colons --with-fingerprint --fingerprint | grep "^fpr" | cut -d: -f 10))
# Warning: $mykeys contain non-signing key. It is not really annoying, but it's not clean.

if [ -z "$mykeys" ] ; then 
    echo -e "\n No private key found here. Didn't you forget to create your\n"\
            "OpenPGP certificat or import the private part here ?\n" >&2
    exit -4
fi

myudid2h="$($gpg --list-key ${mykeys[0]} 2> /dev/null | sed -n ' s,.*(\(udid2;h;[[:xdigit:]]\{40\};[0-9]\+\)[;)].*,\1,p ' | head -n 1)"
#myudid2c="$($gpg --list-secret-keys 2> /dev/null | sed -n ' s,.*(\(udid2;c;[A-Z-]\{0,20\};[A-Z-]\{1,20\};[0-9-]\{10\};e[0-9.+-]\{13\};[0-9]\+\)[;)].*,\1,p ')"
myudid2c="$($gpg --list-key ${mykeys[0]} 2> /dev/null | gawk --re-interval '/\(udid2;c;/ { print gensub(/[^(]*\((udid2;c;[A-Z]{1,20};[A-Z-]{1,20};[0-9-]{10};e[0-9.+-]{13};[0-9]+)[;)].*/, "\\1", "1") ; exit }' )"
myudid1="$($gpg --list-key ${mykeys[0]} 2> /dev/null | sed -n ' s,.*(\(udid1;[^);]\+;[^);]\+;[^);]\+;[^);]\+\)[;)].*,\1,p ' | head -n 1 )" 

if ! [ "$myudid2h" -o "$myudid2c" -o "$myudid1" ] ; then 
    echo -e "\n No udid found in your private datas\n"\
            "please create a valid udid2 and make it signed by some confidents contacts\n" >&2
    exit -4
fi

mkdir -p "$SHome/$curname/c"
head -n $((nstart-2)) "$1" > "$SHome/$curname/c/cset-$setnum.env"
tail -n +$((nstart)) "$1" > "$SHome/$curname/c/cset-$setnum.list"

#myudid="$(([ "$myudid2h" ] && grep -o "$myudid2h" $1 ) || ([ "$myudid2c" ] && grep -o "$myudid2c" $1 ) || ([ "$myudid1" ] && grep -o "$myudid1" $1 ))"
if [ "$myudid2h" ] && myline="$(grep -n "\<$myudid2h\>" "$SHome/$curname/c/cset-$setnum.list" )" ; then
    myudid="$myudid2h"
elif [ "$myudid2c" ] && myline="$(grep -n "\<$myudid2c\>" "$SHome/$curname/c/cset-$setnum.list" )" ; then
    myudid="$myudid2c"
elif [ "$myudid1" ] && myline="$(grep -n "\<$myudid1\>" "$SHome/$curname/c/cset-$setnum.list" )" ; then
    myudid="$myudid1"
else
    echo -e "\n Sorry, your udid is not in the creation set\n" >&2
    exit
fi

myindex=$((${myline%%:*}-2))
mykey="$(echo "$myline" | cut -d ':' -f 2)"

echo -e "\n udid=\"$myudid\"\n key=$mykey position=$myindex"

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

        #KeyID collision in 2 differents creation sheet time are not managed today
        mkdir -p "$SHome/$curname/k/$mykey/w/$setnum"
        rm -f "$SHome/$curname/k/$mykey/w/$setnum/*"
        cfile="$SHome/$curname/k/$mykey/c.$setnum"
        echo -e "d=t2c\nc=$curname\nh=$(sha1sum -t "$1" | cut -d ' ' -f 1)\nb=(" > "$cfile"
        for ((i=0;i<48;i++)) ; do
            if ((factors[i])) ; then
                value="$(echo $(((48-i)%3?(48-i)%3:5))*10^$(((47-i)/3)) | bc -l )"
                for ((j=0;j<factors[i];j++)) ; do
                    k=$((factors[i]*myindex+j))
                    echo -n "$value-$setnum-$k.0 "
                    echo "$value-$setnum-$k c.$setnum" >> "$SHome/$curname/k/$mykey/w/$setnum/$value"
                done
                echo
            fi
        done >> "$cfile"
        echo ")" >> "$cfile"
        #$gpg --detach-sign -u "${mykey}!" --armor --output - "$SHome/$curname/cset/cset.$setnum.env" >> "$cfile"
        $gpg --sign -u "${mykey}!" "$cfile"
        # Then we have to publish this creation... and hurry (before dlimc).
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

