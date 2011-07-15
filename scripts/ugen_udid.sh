#!/bin/bash

SW="OpenUDC - devel"
Version="ugen_udid.sh 0.0.1 ($SW)"

Countries=( "FRA" )

function usage {
echo -e "Usage: $0 [options]\n"\
     "Options:\n"\
     " -h, --help\t\tthis help"\
     " -V, --version\t\tversion"\
     " -f, --file\t\tgeolist file to use" > &2
    exit $1
}

if gpg2 --version 2> /dev/null | head -n 3 ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null | head -n 3 ; then
    gpg="gpg"
else
    echo -e "\nWarning: No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" >&2
    gpg=false
fi

for ((i=0;$#;)) ; do 
    case "$1" in
        -h|--h*) usage ;;
        -V|--vers*) echo $Version ; exit ;;
        -f|--f*)
            shift
            if [ -f "$1" ] ; then
                Country=$(head -n 1 "$1" | cut -d "$(printf "\t")" -f 2 ) 
                GeoFiles[$COUNTRY]="$1"
            else
                echo -e "Error: geolist file $1 does not exist\n" ; usage -1;
            fi ;;
    esac
    shift
done

if ! LANGUAGE=en $gpg --verify ${GeoFile:=geolist_FRA.txt.asc} 2>&1 | grep -o 'Good signature from ".\+(udid2;h;4c5441eb5fbe391b27f6baaa1e8203d1990d98b5;0\>' ; then
    echo "Warning: geolist signature ..."
fi

