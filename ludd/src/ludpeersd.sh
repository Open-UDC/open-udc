#!/usr/bin/bash

    # irc.cat.pdx.edu 6667 : Why not ?
    # irc.oftc.net 6667    : Good
    # irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

function udc_peerw2alljobspipe {
    jobs -r | while IFS="]" read job etc ; do 
        echo -e "$1" > "$TmpDir/peersd/${job:1}.in"
    done
}

function udc_peerk9alljobs {
    jobs | while IFS="]" read job etc ; do 
        kill -9 %${job:1}
    done
}

function peerdiscoverd {
# discover and update peer list
# Argument 1: IrcUser
# Argument 2: IrcComment (which contain protocol, port and directory where to reach OpenUDC API)
# Argument 3: base of IrcNick (to search for other peers)
# Argument 4...: uri where to find/get peers 

allout="$TmpDir/peersd/all.out"
IrcUser="${1:-ludd}"
#IrcComment="http://:80/OpenUDC/$Currency"
IrcComment="$2"
IrcNickb="${3:-$Currency}"
shift 3
vpools=("$@")

local line IrcLogpipe IrcNick src command target args i free IrcDate SrcCurrent=() SrcTimeIn=() 

while true ; do 
    mkdir -p "$TmpDir/peersd"
    mkfifo "$allout"
    fdins=10
    fdi=1
    IrcNickn="$(date +"%s")"
    ptime="0"

    # Initialize Connections
    for vpool in "${vpools[@]}" ; do
        if [[ "$vpool" =~ ^irc://([^/:]*)(:([0-9]*))?/ ]] ; then # Note: this pattern don't support IPv6 address.
            server="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[3]:-6667}"
            mkfifo "$TmpDir/peersd/$fdi.in"
            exec $((fdins+fdi))<> "$TmpDir/peersd/$fdi.in"
            nc "$server" "$port" <&$((fdins+fdi)) >> "$allout" &
            ((fdi++))
        else
            echo "Warning: unsupported vpool uri: $vpool" >&2
        fi
    done

    udc_peerw2alljobspipe "USER $IrcUser 0 _ :$IrcComment\nNICK ${IrcNickb}_$IrcNickn\nMODE ${IrcNickb}_$IrcNick -i"

    while read -t 600 src command target args ; do
        #[[ "$IrcLogpipe" != "cat" ]] && echo "$(date -R)<- $src $command $target $args" >> "$Irclogfile"
        case "$src" in
            #"PING") echo "PONG :hostname" | $IrcLogpipe >> "$Ircfifo" ;;
            "PING") udc_peerw2alljobspipe "PONG $command" ;;
            "ERROR") continue ;;
        esac
        #src="${src:1}" # Remove 1st char ':' 
        case "$command" in
            43[1-6])
                ((IrcNickn-=600))
                udc_peerw2alljobspipe "NICK ${IrcNickb}_$IrcNickn\nMODE ${IrcNickb}_$IrcNickn -i"
                ;;
            352)
                read channel username address server nick flags hops info < <(echo "$args")
                if [[ "$info" =~ ^(https?)://([^/:]*)(:([0-9]*))?/([^ ]*) ]] ; then
                    address="${BASH_REMATCH[2]:-$address}"
                    case "${BASH_REMATCH[1]}" in 
                        http) port="${BASH_REMATCH[4]:-80}" ;;
                        https) port="${BASH_REMATCH[4]:-443}" ;;
                    esac
                    udc_peercheck "${BASH_REMATCH[1]}://$address:$port/${BASH_REMATCH[5]}" "1200" # check peer (if not checked in the 1200sec=20min before)
                fi
                ;;
        esac
        ((i++%8)) || ctime=$(date +"%s")  # "i++%8" to avoid to fork to call $(date ...) each time.
        if ((ctime-ptime>900)) ; then # each 900sec=15min or more
            ptime=$ctime
            udc_peerw2alljobspipe "WHO ${IrcNickb}_*"
            ((j++%32)) || udc_peerclean "86400" # each 32*15min=8h or more, clean peers which have not been checked in the last 86400sec=24hours
        fi

    done < "all.out"

    udc_peerk9alljobs
    rm -rf "$TmpDir/peersd"
done
}

function garbage {
    echo -e "USER $IrcUser 0 _ :$IrcComment\nNICK ${IrcNickb[$fdi]}$IrcNickn\n" >&$((fdins+fdi))
    logstatus=0

    while ((logstatus==0)) ; do 
        if read -t 5 src command target args < "$TmpDir/peersd/[$fdi].out" ; then 

            case "$src" in
                "ERROR") logstatus=-1 ;;
            esac
            src="${src:1}" # Remove 1st char ':' 
            case "$command" in
                NOTICE) echo >> "$Ircfifo" ;;
                43[1-6]) echo -e "NICK ${IrcNickb[$fdi]}$((--IrcNickn))\n" >&$((fdins+fdi)) ;;
                001) logstatus=1 ;;
            esac
        else
            logstatus=-2
        fi
    done
    if ((logstatus<0)) ; then 
        kill %$fdi
        exec $((fdins+fdi))<&-
        exec $((fdouts+fdi))>&-
        rm "$TmpDir/peersd/$fdi."*
    else
        exec $((fdouts+fdi))>> "$allout"
        ((fdi++))
    fi
}

