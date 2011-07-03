#!/bin/bash

grep landmark docs/RGC_arrondissements/arr_paris | sed ' s/.*pagename=\([0-9]*\).*params=\([^_]*\)_N_\([^_]*\).*/\1 \2 \3/ ' | tr '.' ',' | while read arr lat long ; do printf "FRANCE\tPARIS $arr (75)\te+%.3f+00%.3f\n" $lat $long | tr ',' '.' ; done
#echo -e "FRANCE\tPARIS 4 (75)\te+48.86+002.35" # This doesn't not match registery to be different from PARIS 3
#echo -e "FRANCE\tPARIS 9 (75)\te+48.88+002.34" # This doesn't not match registery to be different from PARIS 2

export IFS="$(echo -e "\t")"
#grep -i paris docs/RGC/RGC_2010.txt | while read DEP     COM     ARRD    CANT    ADMI    POPU    SURFACE NOM     XLAMB2  YLAMB2  XLAMBZ  YLAMBZ  XLAMB93 YLAMB93 LONGI_GRD       LATI_GRD        LONGI_DMS       LATI_DMS      ZMIN    ZMAX ; do 
tail -n +2 docs/RGC/RGC_2010.txt | grep -v "^75.*\<PARIS\>" | while read DEP     COM     ARRD    CANT    ADMI    POPU    SURFACE NOM     XLAMB2  YLAMB2  XLAMBZ  YLAMBZ  XLAMB93 YLAMB93 LONGI_GRD       LATI_GRD        LONGI_DMS       LATI_DMS      ZMIN    ZMAX ; do 
    if (($ADMI==6)) ; then continue ; fi ;
    LONGsign="${LONGI_DMS:0:1}" ;
    if ((${#LONGI_DMS}==6)) ; then 
        LONGdeg=$( printf "%03d\n" ${LONGI_DMS:1:1} ) ; 
        LONGmin=${LONGI_DMS:2:2} ; 
        LONGsec=${LONGI_DMS:4:2} ; 
    elif ((${#LONGI_DMS}==7)) ; then 
        LONGdeg=$( printf "%03d\n" ${LONGI_DMS:1:2} ) ; 
        LONGmin=${LONGI_DMS:3:2} ; 
        LONGsec=${LONGI_DMS:5:2} ; 
    else 
        echo "Oups, longitude non gérée ($NOM ($DEP) ${LONGI_DMS})" >&2 ; continue ; 
    fi ; 
    if ((${#LATI_DMS}==6)) ; then 
        LATdeg=$( printf "%02d\n" ${LATI_DMS:0:2} ) ; 
        LATmin=${LATI_DMS:2:2} ; 
        LATsec=${LATI_DMS:4:2} ; 
    else 
        echo "Oups, latitude non gérée ($NOM ($DEP) ${LATI_DMS})" >&2 ; continue ; 
    fi ; 
    LATdec=$(awk -v LATmin="$LATmin" -v LATsec="$LATsec" 'BEGIN{ printf"%.3f\n", LATmin/60+LATsec/3600}');
    LONGdec=$(awk -v LONGmin="$LONGmin" -v LONGsec="$LONGsec" 'BEGIN{ printf"%.3f\n", LONGmin/60+LONGsec/3600}');
    echo -e "FRANCE\t$NOM ($DEP)\te+$LATdeg${LATdec:1}$LONGsign$LONGdeg${LONGdec:1}" ; 
done

