#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

#set -x
. ${0%/*}/lud_set.env || exit 1
lud_init || exit 2
. lud_utils.env || exit 3

helpmsg='
Usage: '"${lud_call}"' [options]
'

for ((i=0;$#;)) ; do
	case "$1" in
		-h|--h*) lud_utils_usage "$helpmsg" ; $lud_exit ;;
		-V|--vers*) echo $udcVersion ; $lud_exit ;;
		*) echo "Error: Unrecognized option $1"; lud_utils_usage "$helpmsg" ; $lud_exit 102 ;;
	esac
	shift
done

while true ; do
	lud_utils_chooseinlist "Please choose what to do ?" 1 \
					 "Register your udid2 for Universal Monetary Dividend" \
					 "Change registered key for Universal Monetary Dividend" \
					 "Generate/Check an udid2" \
					 "Sign or Vouch someone else" \
					 "Synchronyse Monetary creation" \
					 "Check the local balance of your account(s)" \
					 "Make and send a transaction file" \
					 "Check received transaction file(s)" \
					 "quit ${0##*/}" >&2
#"Signalize a (living/deceased) individual" \
#"Update all database" \
	case $? in
	  1)
		$lud_gpg --keyserver "${KeyServList[0]}" --send-keys $mymainkeys
		read -t 3
		;;
	  2)
		echo "Sorry: Not implemented yet." >&2
		read -t 3
		;;
	  3)
		. lud_generator.env
		lud_generator_udid
		read -t 3
		;;
	  4)
		while true ; do 
			read -p " Do you know its udid2 (y/n) ? " rep
			case "$rep" in
			[yYoO]*)
				read -p " Which is ? (udid2;c;...) ? " itsudid
				if ! grep "^udid2;c;[A-Z]\{1,20\};[A-Z-]\{1,20\};[0-9-]\{10\};[0-9.e+-]\{14\};[0-9]\+;\?$" <(echo $itsudid) > /dev/null ; then
					echo "Warning: this id ($myudid) is not a valid udid2" >&2
				fi
				break
				;;
			[nN]*)
				. lud_generator.env
				itsudid="$(lud_generator_udid | sed -n 1p )"
				echo -e "$itsudid\n"
				break
				;;
			*) echo "  please answer \"yes\" or \"no\"" >&2 ;;
			esac
		done
		itsudid="${itsudid%;}" #remove last ';' if present.

		keylist="$(curl -sS "${KeyServList[0]#*//}:11371/pks/lookup?op=index&options=mr&search=$(echo "$itsudid" | ${0%/*}/urlencode.sed)" | grep "^\(pub:\|uid:\)")"
		if [[ "$keylist" != pub:* ]] ; then 
			echo "Error: \"$itsudid\" not found on the keyserver ${KeyServList[0]}"
			continue
		else
			keylist=$( echo "$keylist" | awk ' { if (NR==1)  { sub("^pub:","\"pub:") } else  { sub("^pub:","\" \"pub:") } ; print } END { print "\"" } ' )
			eval keylist=("$keylist") # put the different keys/certs in a array.
			lud_utils_chooseinlist "Which certificate you want to sign ?" 1 "${keylist[@]}"
			itspub=$( echo "${keylist[$(($?-1))]}" | sed -n 's,^pub:\([^:]*\).*,\1,p' )
			$lud_gpg --keyserver "${KeyServList[0]}" --recv-keys "$itspub"
			if [ "${mymainkeys[1]}" ] ; then
				lud_utils_chooseinlist "Using which of your keys ?" 1 "${mymainkeys[@]}"
				$lud_gpg --sign-key -u "${mymainkeys[$(($?-1))]}"\! "$itspub" 
			else
				$lud_gpg --sign-key -u "${mymainkeys[0]}"\! "$itspub" 
			fi
			$lud_gpg --keyserver "${KeyServList[0]}" --send-keys "$itspub"
		fi
		# When did you see this individual last time ?
		# Was she/he dead or alive ?
		# gpg --sign-key -N _dead@-=2011-10-24 -u mykey\! it's_udid2
		read -t 3
		;;
#	  5)
#		# gpg --sign-key -N _alive@-=2011-10-24 -N '!Iam@voucher=2011-10-12' -u mykey\! it's_udid2
#		echo "Sorry: Not implemented yet." >&2
#		read -t 3
#		;;
	  5)
		#UDsyncCreation
		echo "Sorry: Not implemented yet." >&2
		read -t 3
		;;
	  6)
		echo "Sorry: Not implemented yet." >&2
		read -t 3
		continue
	  [[ "${myaccounts[0]}" ]] || echo "No account found."
		for account in "${myaccounts[@]}" ; do
			echo -n "$account: "
			lud_wallet_freadbalance "$account"
		done
		read -t 3
		;;
	  7)
		echo "Sorry: Not implemented yet." >&2
		read -t 3
		continue
		if ((${#myaccounts[@]}>1)) ; then
			lud_utils_chooseinlist "From which account ?" 1 "${myaccounts[@]}" >&2
			account="${myaccounts[$(($?-1))]}"
		else
			account="${myaccounts[0]}"
		fi
		read -p "How much ? " amount >&2
		grains=($(lud_wallet_preparetransaction $((amount)) "$account"))
		ret="$?"
		if ((ret==255)) ; then
			echo "Unknow error" >&2
		elif ((ret==254)); then
			echo "There is not enough money" >&2
		else
			if ((ret)) ; then
				echo "You miss small grains to reach exactly the amount,"
				if ((ret==253)) ; then
					read -p "  and will send at least $ret more, do you want to continue (y/n) ? " rep >&2
				else
					read -p "  and will send $ret more, do you want to continue (y/n) ? " rep >&2
				fi
				case "$rep" in
				  [yY]*)
					ret=0
				  ;;
				  [nN]*) ;; #do Nothing
				  *) echo "  please answer \"yes\" or \"no\"" >&2 ;;
				esac
			fi
			if ((!ret)) ; then
				mapfile < <(sed -n ' s,^[[:xdigit:]]\{40\}:,,p ' "$udcHOME/$Currency/adressbook")
				lud_utils_chooseinlist "To which account ?" 1 "${MAPFILE[@]}" "Other..."
				destkey=$(sed -n "$?p" <(sed -n ' s,\(^[[:xdigit:]]\{40\}\):.*,\1,p ' "$udcHOME/$Currency/adressbook"))
				[[ "$destkey" ]] || read -p "Enter the fingerprint of destination account: " destkey >&2
				#echo -n sended_amount
				echo "$account -> $destkey" >&2
				if ! lud_wallet_maketransaction "$account" "$destkey" "${grains[@]}" >&2 ; then
					echo "Making transaction failed. Return code = $? " >&2
				#else # Send it now ...
				fi
			fi
		fi
		;;
	  8)
		read -t 3
		continue
		read -p "filename ? "
		UDvalidate "$REPLY"
		#echo "function UDvalidate return $?"
		read -t 3
		;;
	  9)
		break
		;;
	  *)
		# should not happen
		echo -e "Oups..." >&2
		break
		;;
	esac
done
