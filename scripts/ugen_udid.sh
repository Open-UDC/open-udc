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
     " -h, --help\t\tthis help\n"\
     " -V, --version\t\tversion\n"\
     " -f, --file\t\tgeolist file to use\n" >&2
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
    $gpg gpg2 --recv-keys --batch --no-verbose --keyserver "$KEYSERVER" "${GEOLISTFPR[0]}"
fi

for ((i=0;$#;)) ; do 
    case "$1" in
        -h|--h*) usage ;;
        -V|--vers*) echo $Version ; exit ;;
        -f|--f*)
            shift
            if [ -f "$1" ] \
                    && Country="$($gpg --no-verbose --batch --decrypt "$1" 2> /dev/null | sed -n '2s,e[0-9.+-]\+\t\([A-Z]\{3\}\)\t.*,\1,p' ;)" \
                    && [ "$Country" ] ; then
                    #Note: The validity of the signature will be checked later in the script
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

function chooseinlist {
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


Countries[${#Countries[@]}]="Other..."
chooseinlist "Please select your Country of Birth..." "${Countries[@]}"
ret=$?
if ((ret==${#Countries[@]})) ; then
    echo -e " Sorry: we can't generate your udid.\n"\
            "Please join the OpenUDC's developpement team to add support for your birthplace <open-udc@googlegroups.com>."
    exit
else
    GFile="${CFiles[((ret-1))]}"
fi

if ! LANGUAGE=en $gpg --verify --no-verbose --batch "$GFile" 2>&1 | grep -o "(${GEOLISTUDID[0]}\>.*)" ; then
    #Note: Trust is not checked.
    echo "Warning: the geolist file "$GFile" is not signed by a recognized signature" >&2
    read -p "The geolist file "$GFile" may provide invalid udid2, do you want to continue ? (y/n) " answer
    case "$answer" in
                Y* | y* | O* | o* )
                true ;;
                *)
                exit ;;
    esac
fi

for ((j=0;;j++)) ; do 
    read -p "Please enter your place of birth ? " answer
    cities="$($gpg --no-verbose --batch --decrypt "$GFile" 2> /dev/null | grep -i "$answer")"
    eval citiesname=($(echo "$cities" | sed ' s,e[0-9.+-]\+\t[A-Z]\{3\}\t\([^"]\+\).*,"\1",'))
    
    chooseinlist "Please validate your place of birth" "${citiesname[@]}" "Other..."
    ret=$?
    if ((ret==${#citiesname[@]}+1)) ; then
        if ((!j)) ; then continue
        else
            echo -e " Sorry: we can't generate your udid.\n"\
            "Please join the OpenUDC's developpement team to add support for your birthplace <open-udc@googlegroups.com>."
            exit
        fi
    else
        bplace="$(echo "$cities" | sed -n "${ret}p" )"
        #echo "$bplace" | sed "s,\(e[0-9.+-]\+\)\t[A-Z]\{3\}\t.*,\1,"
        #echo ${bplace%%$(echo -en "\t")*}
        break;
    fi
done

read -p "Please enter your birth last name (family name) ? " blname
read -p "Please enter your birth first first name (forename) ? " bfname

read -p "Please enter your date of birth ? (YYYY-MM-DD) " bdate
date -d "$bdate" "+%A, %d %B %Y"

#eval $gpg --no-verbose --batch --decrypt "$1" 2> /dev/null | 

