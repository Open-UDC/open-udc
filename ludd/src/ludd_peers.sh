#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

    # irc.cat.pdx.edu 6667 : Why not ?
    # irc.oftc.net 6667    : Good
    # irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

function ludd_peers_w2alljobspipe {
    jobs -r | while IFS="]" read job etc ; do
	echo -e "$1" > "$TmpDir/peersd/${job:1}.in"
    done
}

function ludd_peers_k9alljobs {
    jobs | while IFS="]" read job etc ; do
	kill -9 %${job:1}
    done
}


# replaced old name UDpeersdiscover by the module name
function ludd_peers {
# discover and update peer list
# Argument 1: IrcUser
# Argument 2: IrcComment (which contain protocol, port and directory where to reach OpenUDC API)
# Argument 3: base of IrcNick (to search for other peers)
# Argument 4...: uri where to find/get peers

local wdir="$TmpDir/peersd"
local allout="$wdir/all.out"
local IrcUser="${1:-ludd}"
#IrcComment="http://:80/OpenUDC/$Currency"
local IrcComment="$2"
local IrcNickb="${3:-$Currency}"
shift 3
local pools=("$@")
local fdins=10
local fdi IrcNickn ptime ctime pool server port src command target args
local channel username address server nick flags hops info i j

while true ; do
    mkdir -p "$wdir"
    mkfifo "$allout"
    fdi=1
    IrcNickn="$(date +"%s")"
    ptime=0 ; ctime=0
    i=0 ; j=0

    # Initialize Connections
    for pool in "${pools[@]}" ; do
	if [[ "$pool" =~ ^irc://([^/:]*)(:([0-9]*))?/ ]] ; then # Note: this pattern don't support IPv6 address.
	    server="${BASH_REMATCH[1]}"
	    port="${BASH_REMATCH[3]:-6667}"
	    mkfifo "$TmpDir/peersd/$fdi.in"
	    exec $((fdins+fdi))<> "$TmpDir/peersd/$fdi.in"
	    nc "$server" "$port" <&$((fdins+fdi)) >> "$allout" &
	    ((fdi++))
	else
	    echo "Warning: unsupported vpool uri: $pool" >&2
	fi
    done

    ludd_peers_w2alljobspipe "USER $IrcUser 0 _ :$IrcComment\nNICK ${IrcNickb}_$IrcNickn\nMODE ${IrcNickb}_$IrcNick -i"

    while read -t 600 src command target args ; do
	#[[ "$IrcLogpipe" != "cat" ]] && echo "$(date -R)<- $src $command $target $args" >> "$Irclogfile"
	case "$src" in
	    #"PING") echo "PONG :hostname" | $IrcLogpipe >> "$Ircfifo" ;;
	    "PING") ludd_peers_w2alljobspipe "PONG $command" ;;
	    "ERROR") continue ;;
	esac
	#src="${src:1}" # Remove 1st char ':'
	case "$command" in
	    43[1-6])
		((IrcNickn-=600))
		ludd_peers_w2alljobspipe "NICK ${IrcNickb}_$IrcNickn\nMODE ${IrcNickb}_$IrcNickn -i"
		;;
	    352)
		read channel username address server nick flags hops info < <(echo "$args")
		if [[ "$info" =~ ^(https?)://([^/:]*)(:([0-9]*))?/([^ ]*) ]] ; then
		    address="${BASH_REMATCH[2]:-$address}"
		    case "${BASH_REMATCH[1]}" in
			http) port="${BASH_REMATCH[4]:-80}" ;;
			https) port="${BASH_REMATCH[4]:-443}" ;;
		    esac
		    ludd_peers_check "${BASH_REMATCH[1]}://$address:$port/${BASH_REMATCH[5]}" "1800" # check peer (if not checked in the 1800sec=30min before)
		fi
		;;
	esac
	((i++%8)) || ctime=$(date +"%s")  # "i++%8" to avoid to fork to call $(date ...) each time.
	if ((ctime-ptime>900)) ; then # each 900sec=15min or more
	    ptime=$ctime
	    ludd_peers_w2alljobspipe "WHO ${IrcNickb}_*"
	    ((j++%32)) || ludd_peers_clean "86400" # each 32*15min=8h or more, clean peers which have not been checked in the last 86400sec=24hours
	fi

    done < "all.out"

    ludd_peers_k9alljobs
    rm -rf "$wdir"
done
}

# Local Variables:
# mode: sh
# End:
