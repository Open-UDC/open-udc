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
     " -f, --file\t\tgeolist file to use\n"
    exit $1
}

## Create file descriptor 7 to save STDOUT
exec 7>&1
## then redirect STDOUT to STDERR to avoid using >&2 for each "echo" ...
exec 1>&2

if gpg2 --version > /dev/null 2>&1 ; then 
    gpg="gpg2"
elif gpg --version > /dev/null 2>&1 ; then
    gpg="gpg"
else
    echo -e "\nError: No gpg found in your \$PATH ($PATH)\n"\
            "please install GnuPG (http://www.gnupg.org/)\n" 
    exit -3
fi

if ! $gpg --list-key "${GEOLISTUDID[0]}" 2> /dev/null > /dev/null ; then
    $gpg --recv-keys --batch --no-verbose --keyserver "$KEYSERVER" "${GEOLISTFPR[0]}"
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
                echo "Error: incorrect geolist file $1"  ; usage -1;
            fi ;;
        *) echo "Error: Unrecognized option $1"  ; usage -1;;
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

    if [ -z "${cCountries[0]}" ] ; then # No Custom geolist file in command parameter
        if mkdir -p "${GFile%/*}" \
        && ( curl "https://raw.github.com/jbar/open-udc/master/docs/geolist_${Countries[((ret-1))]}.txt.asc" > "$GFile" \
        || wget -O - "https://raw.github.com/jbar/open-udc/master/docs/geolist_${Countries[((ret-1))]}.txt.asc" > "$GFile" \
        || GET "https://raw.github.com/jbar/open-udc/master/docs/geolist_${Countries[((ret-1))]}.txt.asc" > "$GFile" ) ; then
            echo " File \"$GFile\" updated from git repository"
        else
            echo " Error: unable to retrieve invalid \"$GFile\" from git repository" ; exit -4
        fi
    else
        echo "Warning: the geolist file "$GFile" is not signed by a recognized signature" 
        read -p "The geolist file "$GFile" may provide invalid udid2, do you want to continue ? (y/n) " answer
        case "$answer" in
                Y* | y* | O* | o* )
                ;; # do nothing
                *)
                    exit ;;
        esac
    fi
fi

for ((;;)) ; do 
    for ((j=0;;j++)) ; do 
        read -p "Please enter your place of birth ? " answer
        cities="$($gpg --no-verbose --batch --decrypt "$GFile" 2> /dev/null | sed ' s,\(e[0-9.+-]\+\t\)[A-Z]\{3\}\t,\1,' | grep -i "$answer")"
        eval citiesname=($(echo "$cities" | sed ' s,e[0-9.+-]\+\t\([^"]\+\).*,"\1",'))
        
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

    echo -e "\nNote: Only US-ASCII characters are allowed for first name and last name,\n"\
            "other characters (éçñßزд文...) have to be transposed to US-ASCII charset"
    if echo | uni2ascii 2> /dev/null ; then
        Transposer="uni2ascii -B"
    else
        echo -e "\t(and uni2ascii tool is not installed in your PATH)"
        Transposer="cat"
    fi
    
    for ((;;)) ; do 
        read -p "Please enter your birth last name (family name) ? " blname
        blname="$(echo "$blname" | $Transposer 2> /dev/null | tr '[:lower:]' '[:upper:]' )"
        if echo "$blname" | grep "[A-Z]" > /dev/null ; then
            break
        else
            echo -e "\t(Last name MUST contain at least one [A-Z] character)"
        fi
    done

    for ((;;)) ; do 
        read -p "Please enter your birth first first name (forename) ? " bfname
        bfname="$(echo "$bfname" | $Transposer 2> /dev/null )"
        if echo "$bfname" | grep "[A-Za-z-]" > /dev/null ; then
            break
        else
            echo -e "\t(First name MUST contain at least one [A-Z-] character)"
        fi
    done

    for ((;;)) ; do
        read -p "Please enter your date of birth ? (YYYY-mm-dd) " bdate
        date -d "$bdate" > /dev/null && break
    done

    echo -e "\nSummary:\n"\
            "Last name at birth: $blname\n"\
            "First name at birth: $bfname\n"\
            "Birthdate: $(date -d "$bdate" "+%A, %d %B %Y")\n"\
            "Birthplace: ${bplace##*$(echo -en "\t")}\n"
    read -p "Is that correct ? (y/n) " answer
    case "$answer" in 
        Y* | y* | O* | o* )
            break ;;
    esac
done

blname="$( echo "$blname" | sed -n ' s,.*\(\<[A-Z]\+\>\)[^A-Z]*,\1,p ' | head -c 20 )"
bfname="$( echo "$bfname" | sed ' s,[^a-zA-Z-]*\([a-zA-Z-]\+\).*,\U\1, ' | head -c 20 )"

echo -e "\n\tTa-dah ! ... Your udids are (except of collision) :\n"
sleep 1
## redirect STDOUT to STDOUT
exec >&7

echo "udid2;h;$( echo -n "$blname;$bfname;$bdate;${bplace%%$(echo -en "\t")*}" | sha1sum | head -c 40 );0;"
echo "udid2;c;$blname;$bfname;$bdate;${bplace%%$(echo -en "\t")*};0;"
echo
