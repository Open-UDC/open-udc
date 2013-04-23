#!/bin/bash

Version="2.0 23Apr2013"

HelpMsg=" Usage: ${0##*/} logpath #channel [[#channel2] ...] server [port]

	Example: ${0##*/} \"/tmp/logs/irc/\" \"#monkeysphere\" irc.oftc.net 6667
"

IrcComment="logs: http://domesticserver.org/logs/irc/"

function ircbot {
	# irc.cat.pdx.edu 6667 : Why not ?
	# irc.oftc.net 6667	: Good
	# irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

local Tmpdir="$(mktemp --tmpdir -d irclogger_XXX)" || return 251
trap "rm -rvf \"$Tmpdir\" " EXIT

local Irclogdir="$1"
mkdir -p "$1" || return 250
shift
[ -z "${Irclogdir}" ] && echo -e "Error: invalid logpath argument\n$HelpMsg" >&2 && exit 200

local IrcChans=()
while [[ ${1:0:1} == '#' ]] ; do
	IrcChans=("${IrcChans[@]}" $1)
	mkdir -p "$Irclogdir/${1,,}" || return 250
	shift
done
[ -z "${IrcChans[0]}" ] && echo -e "Error: invalid channel argument\n$HelpMsg" >&2 && exit 200

local IrcServer="$1"
shift
[ -z "$IrcServer" ] && echo -e "Error: invalid channel argument\n$HelpMsg" >&2 && exit 200

local IrcPort="${1:-6667}"

local IrcUser="bot"
local IrcNickb="_rec_"
local IrcNick="$IrcNickb$((RANDOM%8388608))"
local line src command target args chan

while true ; do 

	mkfifo "$Tmpdir/irc.in" || return 249
	mkfifo "$Tmpdir/irc.out" || return 249
	trap EXIT # reset trap on EXIT
	nc "$IrcServer" "$IrcPort" < "$Tmpdir/irc.in" > "$Tmpdir/irc.out" &
	trap "sleep 1 ; jobs -l ; jobs -p | xargs kill -9 2> /dev/null ; rm -rvf \"$Tmpdir\" " EXIT

	exec 10> "$Tmpdir/irc.in"
	exec 11<> "$Tmpdir/irc.out"
	echo -e "\nUSER $IrcUser 0 _ :$IrcComment\nNICK $IrcNick" >&10
	for chan in "${IrcChans[@]}" ; do
		echo "JOIN $chan" >&10
	done

	while read -t 510 src command target args <&11 ; do
		#echo "$(date -R)<- $src $command $target $args"
		case "$src" in
			"PING") echo "PONG $command" >&10 ;;
			"ERROR") break ;;
		esac
		src="${src:1}" # Remove 1st char ':' 
		case "$command" in
			#NOTICE) echo >&10 ;;
			43[1-6])
				IrcNick="$IrcNickb$((RANDOM%8388608))"
				echo "NICK $IrcNick" >&10
				for chan in "${IrcChans[@]}" ; do
					echo "JOIN $chan" >&10
				done
				;;
			JOIN|PART|QUIT)
				SrcNick="${src%%\!*}"
				tmplogfile="$(date "+%Y/%m/%d").txt"
				#To remove f..k.ng \0x0d char ...
				target=${target//$'\r'}
				mkdir -p "$Irclogdir/${target,,}/${tmplogfile%/*}"
				echo "// $(date "+%X%z"): $SrcNick $command // $target" >> "$Irclogdir/${target,,}/$tmplogfile"
				;;
			NICK)
				SrcNick="${src%%\!*}"
				tmplogfile="$(date "+%Y/%m/%d").txt"
				for chan in "${IrcChans[@]}" ; do
					echo "// $(date "+%X%z"): $SrcNick is now know as //$target" >> "$Irclogdir/${chan,,}/$tmplogfile"
				done
				;;
			PRIVMSG)
				SrcNick="${src%%\!*}"
				if [[ "$target" == $IrcNick ]] ; then
					((!(RANDOM%4))) && echo "$(fortune)" | while read line ; do echo "PRIVMSG $SrcNick :$line" ; done >&10
				else
					tmplogfile="$(date "+%Y/%m/%d").txt"
					mkdir -p "$Irclogdir/${target,,}/${tmplogfile%/*}"
					echo "$(date "+%X%z"): $SrcNick $args" >> "$Irclogdir/${target,,}/$tmplogfile"
				fi
				#echo "Message in main chan from $SrcNick: $(echo "${args}" | hexdump -C)" >&2
				;;
		esac
	done
	exec 10>&- 11>&-
	kill $(jobs -pr)
	sleep 1
	jobs -l
	rm -f "$Tmpdir/irc.in" "$Tmpdir/irc.out"
done
}

# Save parameters 
args=("$@")

for ((i=0;$#;)) ; do
	case "$1" in
		-h|--h*) echo "$HelpMsg" ; exit ;;
		-V|--vers*) echo "${0##*/} $Version" ; exit ;;
		-*) echo -e "Error: Unrecognized option $1 \n$HelpMsg" >&2 ; exit 200 ;;
	esac
	shift
done

ircbot "${args[@]}"
exit $?

