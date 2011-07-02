#!/bin/bash

cat docs/RGC/RGC_2010.txt | while read DEP     COM     ARRD    CANT    ADMI    POPU    SURFACE NOM     XLAMB2  YLAMB2  XLAMBZ  YLAMBZ  XLAMB93 YLAMB93 LONGI_GRD       LATI_GRD        LONGI_DMS       LATI_DMS      ZMIN    ZMAX ; do 
    LONGsign="${LONGI_DMS:0:1}" ;
    if ((${#LONGI_DMS}==6)) ; then 
        LONGdeg=${LONGI_DMS:1:1} ; 
        LONGmin=${LONGI_DMS:2:2} ; 
        LONGsec=${LONGI_DMS:4:2} ; 
    elif ((${#LONGI_DMS}==6)) ; then 
        LONGdeg=${LONGI_DMS:1:2} ; 
        LONGmin=${LONGI_DMS:3:2} ; 
        LONGsec=${LONGI_DMS:5:2} ; 
    else 
        echo "Oups, longitude non gérée" >&2 ; exit ; 
    fi ; 
    if ((${#LATI_DMS}==6)) ; then 
        LATdeg=${LATI_DMS:0:2} ; 
        LATmin=${LATI_DMS:2:2} ; 
        LATsec=${LATI_DMS:4:2} ; 
    else 
        echo "Oups, latitude non gérée" >&2 ; exit ; 
    fi ; 
    LAT=$(echo " $LATdeg + $LATmin/60 + $LATsec/3600 " | bc -l ) ; 
    LONG=$(echo " $LONGdeg + $LONGmin/60 + $LONGsec/3600 " | bc -l ) ; 
    echo -e "$DEP\t$COM\t$ADMI\t$NOM\te+$LAT$LONGsign$LONG" ; 
done

