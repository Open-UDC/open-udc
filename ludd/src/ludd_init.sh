#!/bin/bash


helpmsg='
Usage: '"${0##*/}"' [options]
Options:
	-d, --dir	directory (default: $HOME of .ludd user if root, or $HOME/.ludd if not).
	-h, --help	this help
	-V, --version	version
'

function ludd_chooseinlist {
# Argument 1: Prompt before the list
# Argument 2(optionnal): if argument 2 is a number>0, it indicates the number of item by line - defaut: 3.
# Arguments 2,3...n : items to choose
# Return the number of the choosen item, 0 if no items.

	local ret=0 nperline=3 n
	echo -n "$1"
	shift
	(($1>0)) && nperline=$1 && shift
	n=$#
	for ((i=0;$#;)) ; do
		if ((i%nperline)) ; then
			echo -en "\t\t"
		else
			echo -en "\n\t"
		fi
		echo -en "$((++i))) $1"
		shift
	done
	echo
	while ! ((ret)) || ((ret<1 || ret>n)) ; do
		read -p "Reply (1-$n) ? " ret
	done
	return $ret
}

function ludd_genbotkey {
	for ((;;)) ; do
		for ((;;)) ; do
			read -p "What is ur udid2 (udid2;c;...) ? " myudid
			grep "^udid2;c;[A-Z]\{1,20\};[A-Z-]\{1,20\};[0-9-]\{10\};[0-9.e+-]\{14\};[0-9]\+;\?$" <(echo $myudid) > /dev/null && break
		done
		read -p "your bot name ? " mname
		for ((;;)) ; do
			read -p "Bot email adress [Iam@unused.email] ? " email
			[[ "$email" ]] || email="Iam@unused.email"
			grep "^[^@[:space:]]\+@[^.[:space:]]\+\.[^[:space:]]\+$" <(echo $email) > /dev/null && break
		done

		echo -e "\nSummary:\n"\
				"Bot Name: $mname\n"\
				"Bot Owner: $myudid\n"\
				"email: $email\n" >&2
		read -p "Is that correct ? (y/n) " answer
		case "$answer" in
			Y* | y* | O* | o* )
				break ;;
		esac
	done


	cat << EOF | gpg --command-fd 0 --status-file /dev/null --allow-freeform-uid --gen-key --no-use-agent 2> /dev/null
4

8y
$mname
$email
udbot1;$myudid;
o


EOF

return $?
}


refdir=$(grep "^.ludd:" /etc/passwd | cut -d ":" -f 6)

if [[ ! "$refdir" ]] ; then
	echo "${0##*/}: Error: Missing ref dir (HOME of .ludd system user)"
	exit 1
fi

if (($(id -u))) ; then
	dir="$HOME/.ludd"
else
	isroot=1
	dir="$refdir"
fi

for ((i=0;$#;)) ; do
	case "$1" in
		-d|--dir*) shift; dir="$1" ;;
		-h|--h*) echo "$helpmsg" ; $lud_exit ;;
		-V|--vers*) echo $udcVersion ; $lud_exit ;;
		*) echo "Error: Unrecognized option $1"; echo "$helpmsg" ; exit 2 ;;
	esac
	shift
done

mkdir -p "$dir/pub/self" "$dir/pub/d" "$dir/pub/k"
if ((isroot)) ; then
	chown .ludd "$dir/pub/self" "$dir/pub/d" "$dir/pub/k"
fi

if [[ "$dir" != "$refdir" ]] ; then
	cp -avf "$refdir/pub/udid2" "$dir/pub"
	cp -avf "$refdir/pub/in" "$dir/pub"
	cp -avf "$refdir/pub/pks" "$dir/pub"
	cp -avf "$refdir/pub/c" "$dir/pub"
fi

mybotkeys=($(gpg --list-secret-keys --with-colons --with-fingerprint "udbot1;udid2;" | grep "^fpr" | cut -d: -f 10))

echo "NOTE: passphrase to cypher bot's private key is unsupported yet".
ludd_chooseinlist "bot key to use ?" 1 "create a new one" "${mybotkeys[@]}"

bki=$?
case $bki in 
	0)
		exit
		;;
	1)
		ludd_genbotkey || exit 4
		mybotkeys=($(gpg --list-secret-keys --with-colons --with-fingerprint "udbot1;udid2;" | grep "^fpr" | cut -d: -f 10))
		bki=$((${#mybotkeys[@]}-1))
		;;
	*)
		((bki-=2))
esac

cd "$dir"
echo "${mybotkeys[$bki]}" > pub/self/fpr

if ((isroot)) ; then
	gpg --export "${mybotkeys[$bki]}" | gpg --import --homedir "$refdir/.gnupg"
	chown -R .ludd "$refdir/.gnupg"
fi

