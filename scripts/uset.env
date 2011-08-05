#!/bin/bash

udcSW="OpenUDC - devel"
udcHOME="$HOME/.openudc"

udcKEYSERVER="keys.gnupg.net"

udcGEOLISTFPR=("0F16B563D2768EA62B36A13C442C7E45EEF5EAE6")
udcGEOLISTUDID=("udid2;h;4c5441eb5fbe391b27f6baaa1e8203d1990d98b5;0")
udcCountries=("FRA")

function udc_getgpg {
# Argument 1: "Warning" or "Error" (default: "Warning")
# Return -1 if fail, or true and the gpg on stdout.
if gpg2 --version > /dev/null 2>&1 ; then 
    echo gpg2
elif gpg --version > /dev/null 2>&1 ; then
    echo gpg
else
    echo -e "\n$0:${1:-Warning}: No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" >&2
    return -1
fi
}

function udc_chooseinlist {
# Argument 1: Prompt before the list
# Arguments 2...n : items to choose
# Return the number of the choosen item, 0 if no items.
    ret=0
    echo -n "$1"
    shift
    n=$#
    for ((i=0;$#;)) ; do
        if ((i%3)) ; then 
            echo -en "\t\t"
        else
            echo -en "\n\t"
        fi
        echo -en "$((++i))) $1"
        shift
    done
    echo
    while ((ret<1 || ret>n)) ; do
        read -p "Reply (1-$n) ? " ret
    done
    return $ret
}

