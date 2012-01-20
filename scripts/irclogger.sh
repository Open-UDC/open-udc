#!/bin/bash

function ircbot {
    # irc.cat.pdx.edu 6667 : Why not ?
    # irc.oftc.net 6667    : Good
    # irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

if (($#<3)) ; then
    echo -e "\n Usage: $0 logpath channel server [port]\n\n"\
    "Example: $0 \"/tmp/logs/irc/#monkeysphere/\" \"#monkeysphere\" irc.oftc.net 6667" >&2
    return 255
fi

local Tmpdir="$(mktemp --tmpdir -d irclogger_XXX)" || return 251
trap "rm -rvf \"$Tmpdir\" " EXIT

local Irclogdir="$1"
mkdir -p "$1" || return 250
local IrcUser="bot"
local IrcChan="${2:-#udc.test2}"
local IrcComment="$IrcChan logs: http://..."
local IrcNickb="_rec_"
local IrcNick="$IrcNickb$((RANDOM%8388608))"
local line src command target args

while true ; do 

    mkfifo "$Tmpdir/irc.in" || return 249
    mkfifo "$Tmpdir/irc.out" || return 249
    trap EXIT # reset trap on EXIT
    nc "${3:-irc.lfnet.org}" "${4:-6667}" < "$Tmpdir/irc.in" > "$Tmpdir/irc.out" &
    trap "sleep 1 ; jobs -l ; jobs -p | xargs kill -9 2> /dev/null ; rm -rvf \"$Tmpdir\" " EXIT

    exec 10> "$Tmpdir/irc.in"
    exec 11<> "$Tmpdir/irc.out"
    echo -e "\nUSER $IrcUser 0 _ :$IrcComment\nNICK $IrcNick\nJOIN $IrcChan" >&10

    while read -t 510 src command target args <&11 ; do
        #echo "$(date -R)<- $src $command $target $args"
        case "$src" in
            "PING") echo "PONG $command" >&10 ;;
            "ERROR") break ;;
        esac
        src="${src:1}" # Remove 1st char ':' 
        case "$command" in
            #NOTICE) echo >&10 ;;
            43[1-6]) IrcNick="$IrcNickb$((RANDOM%8388608))" ; echo -e "NICK $IrcNick\nJOIN $IrcChan" >&10 ;;
            JOIN|PART|QUIT)
                SrcNick="${src%%\!*}"
                tmplogfile="$(date "+%Y/%m/%d").txt"
                mkdir -p "$Irclogdir/${tmplogfile%/*}"
                echo "// $(date "+%X%z"): $SrcNick $command // $target" >> "$Irclogdir/$tmplogfile"
                ;;
            NICK)
                SrcNick="${src%%\!*}"
                tmplogfile="$(date "+%Y/%m/%d").txt"
                mkdir -p "$Irclogdir/${tmplogfile%/*}"
                echo "// $(date "+%X%z"): $SrcNick is now know as //$target" >> "$Irclogdir/$tmplogfile"
                ;;
            PRIVMSG)
                SrcNick="${src%%\!*}"
                case "$target" in
                  "$IrcChan")
			tmplogfile="$(date "+%Y/%m/%d").txt"
			mkdir -p "$Irclogdir/${tmplogfile%/*}"
        		echo "$(date "+%X%z"): $SrcNick $args" >> "$Irclogdir/$tmplogfile"
                        #echo "Message in main chan from $SrcNick: $(echo "${args}" | hexdump -C)" >&2
                       ;;
                  "$IrcNick") ((!(RANDOM%4))) && echo "$(fortune)" | while read line ; do echo "PRIVMSG $SrcNick :$line" ; done >&10 ;;
                esac
        esac
    done
    exec 10>&- 11>&-
    kill $(jobs -pr)
    sleep 1
    jobs -l
    rm -f "$Tmpdir/irc.in" "$Tmpdir/irc.out"
done
}

ircbot $@
exit $?

