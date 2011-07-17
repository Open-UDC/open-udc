#!/bin/bash

SW="OpenUDC - devel"
UDCHOME="$HOME/.openudc"
KEYSERVER="keys.gnupg.net"
GEOLISTFPR=("0F16B563D2768EA62B36A13C442C7E45EEF5EAE6")
GEOLISTUDID=("udid2;h;4c5441eb5fbe391b27f6baaa1e8203d1990d98b5;0")

Version="ugen_udid.sh 0.0.1 ($SW)"

Countries=("FRA")
for i in ${!Countries[@]} ; do 
    CFiles[$i]="$UDCHOME/udid2/geolist_${Countries[$i]}.txt.asc"
done

function usage {
echo -e "Usage: $0 [options]\n"\
     "Options:\n"\
     " -h, --help\t\tthis help"\
     " -V, --version\t\tversion"\
     " -f, --file\t\tgeolist file to use" >&2
    exit $1
}

if gpg2 --version 2> /dev/null | head -n 3 ; then 
    gpg="gpg2"
elif gpg --version 2> /dev/null | head -n 3 ; then
    gpg="gpg"
else
    echo -e "\nError: No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" >&2
    exit -3
fi

if ! $gpg --list-key "${GEOLISTUDID[0]}" 2> /dev/null > /dev/null ; then
    $gpg gpg2 --recv-keys --batch --no-verbose --keyserver "$KEYSERVER" "$GEOLISTFPR"
fi

for ((i=0;$#;)) ; do 
    case "$1" in
        -h|--h*) usage ;;
        -V|--vers*) echo $Version ; exit ;;
        -f|--f*)
            shift
            if [ -f "$1" ] && Country="$(sed -n '4s,e[0-9+.]\+\t\([A-Z]\{3\}\)\t.*,\1,p' "$1" )" && [ "$Country" ] ; then
                cCountries[$i]="$Country"
                cCFiles[$((i++))]="$1"
                Countries="${cCountries[@]}"
                CFiles="${cCFiles[@]}"
            else
                echo "Error: incorrect geolist file $1" >&2 ; usage -1;
            fi ;;
        *) echo "Error: Unrecognized option $1" >&2 ; usage -1;;
    esac
    shift
done

function chooseintab {
    ret=0
    tabs=$(eval echo "\${#$2[@]}")
    if ((tabs==1)) ; then
        echo "$(eval echo "\${$2[0]}") $3"
        return 1
    fi
    echo -n "$1"
    for i in $(eval echo \${!$2[@]}) ; do
        ((i%3)) || echo && echo -en "\t\t"
        echo -en "$((i+1))) $(eval echo "\${$2[$i]}")"
    done
    echo
    while ((ret<1 || ret>tabs)) ; do
        read -p "Reply (1-$tabs) ? " ret
    done
    return $ret
}


Countries[${#Countries[@]}]="Other..."
chooseintab "Please select your Country of Birth..." Countries
ret=$?
if ((ret==${#Countries[@]})) ; then
    echo -e " Sorry: we can't generate your udid.\n"\
            "Please join the OpenUDC's developpement team to add support for your birthplace <open-udc@googlegroups.com>."
    exit
else
    GFile="${CFiles[((ret-1))]}"
fi

if ! LANGUAGE=en $gpg --verify --no-verbose --batch "$GFile" 2>&1 | grep -o "(${GEOLISTUDID[0]}\>.*)" ; then
    echo "Warning: geolist signature ..." >&2
    #Note: Trust is not checked.
fi


