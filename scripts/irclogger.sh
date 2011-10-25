#!/usr/bin/env bash

Currency="test2"
Ircfifo="/tmp/ircfifo"

function irclogger {
    # irc.cat.pdx.edu 6667 : Why not ?
    # irc.oftc.net 6667    : Good
    # irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

local line IrcLogpipe IrcNick src command target args i free IrcDate SrcCurrent=() SrcTimeIn=() 
local IrcUser="bot"
local IrcComment="http://..."
local IrcChan="#udc.$Currency"
#local Irclogfile="/tmp/irc_$IrcUser.log"
local Irclogdir="$1/$Currency/irc_logs/$IrcChan"
#[[ "$2" ]] && IrcLogpipe="tee -a $Irclogfile" || IrcLogpipe="cat"
local IrcServ="irc.lfnet.org 6667"

trap "rm -vf \"$Ircfifo\" ; ps -o pid,command | while read pid comm ; do [[ \"\$comm\" =~ ^\"tail -f $Ircfifo\" ]] && kill \$pid ; done " EXIT

while true ; do 
    IrcNick="logger"
    mkfifo "$Ircfifo" || return 249

    while read -t 510 src command target args ; do
        #[[ "$IrcLogpipe" != "cat" ]] && echo "$(date -R)<- $src $command $target $args" >> "$Irclogfile"
        case "$src" in
            #"PING") echo "PONG :hostname" | $IrcLogpipe >> "$Ircfifo" ;;
            "PING") echo "PONG :hostname" >> "$Ircfifo" ;;
            "ERROR") break ;;
        esac
        src="${src:1}" # Remove 1st char ':' 
        case "$command" in
            NOTICE) echo >> "$Ircfifo" ;;
            #43?) IrcNick="_$IrcNick" ; echo -e "NICK $IrcNick\nJOIN $IrcChan" | $IrcLogpipe >> "$Ircfifo" ;;
            43?) IrcNick="_$IrcNick" ; echo -e "NICK $IrcNick\nJOIN $IrcChan" >> "$Ircfifo" ;;
            PRIVMSG)
                SrcNick="${src%%\!*}"
                case "$target" in
                    "$IrcChan")
			tmplogfile="$(date "+%Y/%m/%d").txt"
			mkdir -p "$Irclogdir/${tmplogfile%/*}"
        		echo "$(date "+%X%z"): $SrcNick $args" >> "$Irclogdir/$tmplogfile"
                        #echo "Message in main chan from $SrcNick: $(echo "${args}" | hexdump -C)" >&2
                       ;;
                    "$IrcNick") ((!(RANDOM%4))) && echo "$(fortune)" | while read line ; do echo "PRIVMSG $SrcNick :$line" ; done >> "$Ircfifo" ;;
                esac
        esac
    done < <( ( echo -e "USER $IrcUser 0 _ :$IrcComment\nNICK $IrcNick\nJOIN $IrcChan" ; tail -f "$Ircfifo" ) | nc $IrcServ )
    ps -o pid,command | while read pid comm ; do [[ "$comm" =~ ^"tail -f $Ircfifo" ]] && kill $pid ; done 
    rm -f "$Ircfifo" 
done
}

irclogger "${1:-/home/www/OpenUDC}"

