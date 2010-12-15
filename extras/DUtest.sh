#!/bin/bash

years=${1:-80}
rate=${2:-0.5}
dustart=${3:-100}
gstart=$( echo "scale=3 ; $dustart*100/$rate+$dustart" | bc -l )
sstart=${4:-$gstart}

echo "initial credit ($sstart) should be $gstart to start " 

#echo 'du='$dustart' ; for (j=0;j<'$years';j++) { for (i=0;i<12;i++) { du+=du*'$rate'/100 ; print j*12+i," ",du,"\n" } } ' | bc -l > "du.dat"
#echo 'du='$dustart' ; sb='$sstart' ; for (j=0;j<'$years';j++) { for (i=0;i<12;i++) { du+=du*'$rate'/100 ; sb+=du ; print j*12+i," ",sb,"\n" } } ' | bc -l > "sommedu.dat"
echo 'du='$dustart' ; sb='$sstart' ; for (j=0;j<'$years';j++) { for (i=0;i<12;i++) { du+=du*'$rate'/100 ; sb+=du ; per=100*du/sb ; print j*12+i," ",per,"\n" } } ' | bc -l > "dsomme.dat"

#echo ' plot "sommedu.dat" with boxes ; pause 20 ' | gnuplot &
#echo ' plot "sommedu.dat" with boxes ; pause 20 ' | gnuplot &
echo ' plot "dsomme.dat" ; pause 20 ' | gnuplot &

