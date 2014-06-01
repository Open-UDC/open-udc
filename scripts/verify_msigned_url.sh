#!/bin/bash
version="0.1 01Jun2014."

hlpmsg="
${0##*/} permit to verify the OpenPGP signature(s) inside a multipart/msigned HTTP response.

 Usage: $0 [options] url
 Options:
	-k|--keep       keep all the parts or the received response inside a temporary directory.
	-h|--help       print this help and exit.
	-V|--version    show version and exit.
"
#-f|--fetch      If a signature is done by an unkown OpenPGP keys, get it for your favorite keyserver.

x0d="$(printf "\x0d")"

case "$1" in 
	-k|--keep)
		keep="yes"
		shift
		;;
	-h|--help)
		echo "$hlpmsg"
		exit
		;;
	-V|--version)
		echo "$0/$version ."
		exit
		;;
esac

if (($# !=1 )) ; then
	echo "$hlpmsg"
	exit 255
fi

function quit {
	#echo $?
	if [ "$keep" ] ; then
		echo -en "\n$tmpdir/ -> "
		ls -m "$tmpdir"
	else
		rm -rf "$tmpdir"
	fi
}

tmpdir="$(mktemp -d)" || exit
trap quit EXIT

cd "$tmpdir"

#curl -v -H "Accept: multipart/msigned" "$1" 2>&1 > body | tee header >&2
curl -v -H "Accept: multipart/msigned" -D header "$1" > content || exit
echo

#ctypeh="$(grep -i "< Content-Type:" header)"
ctypeh="$(grep -i "^Content-Type:" header)"

if ! echo "$ctypeh" | grep "Content-Type" > /dev/null ; then
	echo "Warning: case fantasy: \"$(echo "$ctypeh" | grep -oi "Content-Type")\" instead of \"Content-Type\"."
fi

if ! ctype="$(echo "$ctypeh" | grep -io "multipart/msigned")" ; then
	echo "Error: response isn't multipart/msigned."
	exit 254
fi

if ! echo "$ctype" | grep "multipart/msigned" > /dev/null ; then
	echo "Warning: case fantasy: \"$ctype\" instead of \"multipart/msigned\"."
fi

boundary="$(echo "$ctypeh" | sed -n " s,.*boundary=\([^ ;$x0d]\+\).*,\1,p " )"
if [ "${boundary::1}" == '"' ] ; then
	boundary="$(echo "$ctypeh" | sed -n ' s,.*boundary="\([^"]\+\).*,\1,p ' )"
fi
#echo "$boundary" | hexdump -C


if ! [ "$boundary" ] ; then
	fl="$(head -n 1 content)"
	echo -n "Warning: no boundary in the HTTP header"
	if [ "${fl::2}" == "--" ] && [ "${fl: -1}" == "$x0d" ] && ((${#fl}<100)) ; then
		echo ", will use the one given by the first line."
		boundary="${fl:2:-1}"
	else
		echo -e ".\nError: first line isn't a boudary line."
		exit 253
	fi
	unset fl
fi

nsigs=$(echo "$ctypeh" | sed -n ' s,.*nsigs=\([^ ;]\+\).*,\1,p ' )
if ! [ "$nsigs" ] ; then
	echo "Warning: nsigs parameter absent, assuming nsigs=1."
	nsigs=1
elif ! ((nsigs)) ; then
	echo "Error: $nsigs: incorrect value for nsigs parameter."
	exit 252
fi

echo

function extract {
	local line pline bound="$1" i=0
	shift

	read line
	((i++))
	if [ "$line" != "--$bound$x0d" ] ; then
		echo "$line" | hexdump -C
		echo "--$bound" | hexdump -C
		echo "Error: $nsigs: incorrect boundary at line 0."
		return 250;
	fi

	while [ "$1" ] && read line ; do
		((i++))
		if [ "$line" == "$x0d" -o -z "$line" ] ; then
			echo "Error: line $i: found an empty line instead of an expected header"
			return 250;
		fi
		# display headers
		echo $line
		while read line ; do
			((i++))
			[ "$line" == "$x0d" -o -z "$line" ] && break
			echo "$line"
		done
		# copy content
		echo
		read pline || break
		((i++))
		if [ "$pline" == "--$bound$x0d" -o  "$pline" == "--${bound}--$x0d" ] ; then
			echo "Warning: no data in this part."
			echo -n > "$1"
			shift
		else
			while read line ; do
				((i++))
				if [ "$line" == "--$bound$x0d" -o  "$line" == "--${bound}--$x0d" ] &&  [ "${pline: -1}" == "$x0d" ] ; then
					echo -n "${pline:: -1}" >> "$1"
					stat -c "%s bytes -> %n" "$1" 
					shift
					break
				else
					echo "$pline" >> "$1"
				fi
				pline="$line"
			done
		fi
		echo
	done

	if [ "$line" == "--${bound}--$x0d" ] && [ -z "$1" ] ; then
		echo "OK: closing boundary in its expected position."
	elif [ "$1" ] ; then 
		echo "Warning: data ended prematurely, before retreiving completely $@"
	else
		echo "Warning: after line $i: there are much data than expected"
	fi
}

if ((nsigs>0)) ; then
	order="message"
	for ((i=0;i<nsigs;i++)) ; do
		order="$order sig$i"
	done
else
	for ((i=0;i<-nsigs;i++)) ; do
		order="$order sig$i"
	done
	order="$order message"
fi

extract "$boundary" $order < content

for sig in sig* ; do 
	echo -e "\ngpg --verify $sig message ->"
	gpg --verify $sig message
done

