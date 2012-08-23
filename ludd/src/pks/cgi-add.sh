#!/bin/bash
export LANG=C

function urldec {
while ((i<$1)) ; do 
	read -t 1 -N 1 encoded
	if [[ "$encoded" == % ]] ; then
		read -t 1 -N 2 encoded
		printf "\x$encoded"
		((i+=3))
	else
		echo -n "$encoded"
		((i++))
	fi
done
}

# first 8 char should be "keytext=" which gpg don't recognize
if ! ((CONTENT_LENGTH>8)) || ! read -t 1 -N 8 || ! response="$(urldec $CONTENT_LENGTH | gpg --armor --fast-import 2>&1 )" ; then
	echo "HTTP/1.0 500 OK"
fi

cat << EOF
Server: ludd/0.1.0
Content-type: text/plain
Expires: $(date -u '+%a, %d %b %Y %H:%M:%S %Z')

EOF

if ((CONTENT_LENGTH>8)) ; then
	echo "$response"
else
	echo "Only non-empty POST containing OpenPGP key(s) are accepted here !"
fi
