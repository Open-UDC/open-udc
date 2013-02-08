#!/bin/bash

# This script should be modified depending on the asked country.
# For example few populations are well known in Ukraina, so we need to comment
# the population filter ; also during the communism, only the region of birth
# was registered, so we need to add regions (A) in the fclass filter.
# Sometime also, it is more accurate to use admin2 instead of admin1 (example: Italia) 

#cd "$TMPDIR" || cd "$TMP" || exit

read -p "Enter the 2-letters country code: " ccode
wget -c "http://download.geonames.org/export/dump/$ccode.zip" || exit

read -p "Enter the 3-letters country code: " Country

echo "writing geolist_$Country.txt..." >&2
previousloc=""
export IFS="$(echo -e "\t")"
unzip -p "$ccode.zip" "$ccode.txt" | sed "s,\t\t,\t \t,g" | while read geonameid name asciiname alternatenames latitude longitude fclass fcode cc1 cc2 admin1 admin2 admin3 admin4 population etc ; do
# only get cities/villages (P) or regions/states/countries (A)
	[[ "$fclass" =~ [P] ]] || continue
# ...with a known and positive population
	((population)) || continue
# ...with a known country/regions/state code
	[[ "$admin1" == " " ]] && continue
# ...which have not be just read previously (but with a different coordinate :-( )
	[[ "$name ($admin1)" == "$previousloc" ]] && continue
	echo -n "+" >&2
	if [[ "${latitude:0:1}" =~ - ]] ; then
		latitude="$(printf "%06.02f" "${latitude/./,}" | tr ',' '.')"
	else
		latitude="$(printf "+%05.02f" "${latitude/./,}" | tr ',' '.')"
	fi
	if [[ "${longitude:0:1}" =~ - ]] ; then
		longitude="$(printf "%07.02f" "${longitude/./,}" | tr ',' '.')"
	else
		longitude="$(printf "+%06.02f" "${longitude/./,}" | tr ',' '.')"
	fi
	echo -e "e$latitude$longitude\t$Country\t$name ($admin1)"
	previousloc="$name ($admin1)"
	[[ "$asciiname" == "$name" ]] || echo -e "e$latitude$longitude\t$Country\t$asciiname ($admin1)"
	echo "$alternatenames" | sed "s;,;\n;g" | while read altername ; do
		[[ "$altername" =~ ^[[:space:]]+$ ]] && continue
		[[ "$altername" == "$name" ]] || [[ "$altername" == "$asciiname" ]] || echo -e "e$latitude$longitude\t$Country\t$altername ($admin1)"
	done
done | sort -u > "geolist_$Country.txt"
echo >&2
#rm -v "$ccode.zip"

