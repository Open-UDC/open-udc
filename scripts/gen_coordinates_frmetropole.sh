#!/bin/bash

#grep landmark docs/RGC_arrondissements/arr_paris | sed ' s/.*pagename=\([0-9]*\).*params=\([^_]*\)_N_\([^_]*\).*/\1 \2 \3/ ' | tr '.' ',' | while read arr lat long ; do printf "FRANCE\tPARIS $arr (75)\te+%.3f+00%.3f\n" $lat $long | tr ',' '.' ; done
#"FRANCE\tPARIS 4 (75)\te+48.86+002.35" doesn't not match registery (e+48.86+002.36) to be different from PARIS 3
#"FRANCE\tPARIS 9 (75)\te+48.88+002.34" doesn't not match registery (e+48.87+002.34) to be different from PARIS 2
#"FRANCE\tPARIS 17 (75)\te+48.89+002.32" doesn't not match registery (e+48.88+002.32) to be different from PARIS 8
cat << EOF
FRANCE  PARIS 1 (75)    e+48.86+002.34
FRANCE  PARIS 2 (75)    e+48.87+002.34
FRANCE  PARIS 3 (75)    e+48.86+002.36
FRANCE  PARIS 4 (75)    e+48.86+002.35
FRANCE  PARIS 5 (75)    e+48.85+002.34
FRANCE  PARIS 6 (75)    e+48.85+002.33
FRANCE  PARIS 7 (75)    e+48.86+002.32
FRANCE  PARIS 8 (75)    e+48.88+002.32
FRANCE  PARIS 9 (75)    e+48.88+002.34
FRANCE  PARIS 10 (75)   e+48.87+002.36
FRANCE  PARIS 11 (75)   e+48.86+002.38
FRANCE  PARIS 12 (75)   e+48.84+002.39
FRANCE  PARIS 13 (75)   e+48.83+002.36
FRANCE  PARIS 14 (75)   e+48.83+002.33
FRANCE  PARIS 15 (75)   e+48.84+002.30
FRANCE  PARIS 16 (75)   e+48.86+002.28
FRANCE  PARIS 17 (75)   e+48.89+002.32
FRANCE  PARIS 18 (75)   e+48.89+002.34
FRANCE  PARIS 19 (75)   e+48.88+002.38
FRANCE  PARIS 20 (75)   e+48.87+002.40
EOF

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
    LATdec=$(awk -v LATmin="$LATmin" -v LATsec="$LATsec" 'BEGIN{ printf"%.2f\n", LATmin/60+LATsec/3600}');
    LONGdec=$(awk -v LONGmin="$LONGmin" -v LONGsec="$LONGsec" 'BEGIN{ printf"%.2f\n", LONGmin/60+LONGsec/3600}');
    if [ "e+$LATdeg${LATdec:1}$LONGsign$LONGdeg${LONGdec:1}" == "e+48.61+007.75" -a "$NOM" == "SCHILTIGHEIM" ] ; then
	echo -e "FRANCE\t$NOM ($DEP)\te+48.61+007.77" ;
    elif [ "e+$LATdeg${LATdec:1}$LONGsign$LONGdeg${LONGdec:1}" == "e+48.88+002.71" -a "$NOM" == "THORIGNY-SUR-MARNE" ] ; then
	echo -e "FRANCE\t$NOM ($DEP)\te+48.89+002.71" ;
    else
	echo -e "FRANCE\t$NOM ($DEP)\te+$LATdeg${LATdec:1}$LONGsign$LONGdeg${LONGdec:1}" ;
    fi
done
