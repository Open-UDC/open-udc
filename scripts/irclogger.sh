#!/bin/bash

Version="2.3 26Apr2013"

HelpMsg="
 Usage: ${0##*/} logpath #channel [[#channel2] ...] server [port]

	Example: ${0##*/} \"/tmp/logs/irc/\" \"#monkeysphere\" irc.oftc.net 6667

	(Don't forget to escape or protect the sharp character '#')
"

IrcComment="I am a tiny bash irc logger, I may easily become a real bot. My DNA (source code): https://github.com/Open-udc/open-udc/blob/master/scripts/irclogger.sh ."

export IFS="$IFS"$'\r' # add f..k.ng \x0d char to the list of field separators ...

FileExt="txt"
# Bold frontiers
B="*"
B_="*"
# Italic frontiers
I="/ "
I_=" /"

# TODO: Manage html and markdown (.md) outputs
#Transposer="cat" # dummy Transposer
#Transposer="sed  ' s_\&_\&amp;_g ; s_<_\&lt;_g ; s_>_\&gt;_g '" # html Transposer

function ircbot {
	# irc.cat.pdx.edu 6667 : Why not ?
	# irc.oftc.net 6667	: Good
	# irc.lfnet.org 6667   : The same as bitcoin, solidcoin, namecoin ... ;-)

local Tmpdir="$(mktemp --tmpdir -d irclogger_XXX)" || return 251
trap "rm -rvf \"$Tmpdir\" " EXIT

local Irclogdir="$1"
shift
[ -z "${Irclogdir}" ] && echo -e "Error: invalid logpath argument\n$HelpMsg" >&2 && exit 200

local IrcChans=()
while [[ ${1:0:1} == '#' ]] ; do
	IrcChans=("${IrcChans[@]}" $1)
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
local line chan src command target args logfile tdir

while true ; do 

	mkfifo "$Tmpdir/irc.in" || return 249
	mkfifo "$Tmpdir/irc.out" || return 249
	for chan in "${IrcChans[@]}" ; do
		mkdir -p "$Irclogdir/${chan,,}" || return 250
	done

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
		# Uncomment following to TRACE INPUT
		#echo "$(date -R)<- $src $command $target $args" # >> "/tmp/irc_$IrcNick.trace"
		case "$src" in
			"PING") echo "PONG $command" >&10 ; continue ;;
			"ERROR") break ;;
		esac
		src="${src:1}" # Remove 1st char ':' 
		case "$command" in
			332) # Topic
				args=($args)
				chan="${args[0]}"
				args[0]=""

				logfile="$(date "+%Y/%m/%d").$FileExt"
				tdir=${chan,,}
				mkdir -p "$Irclogdir/$tdir/${logfile%/*}"
				echo "$I$(date "+%X%z"):$I_ Topic${args[*]}" >> "$Irclogdir/$tdir/$logfile"
				;;
			43[1-6])
				IrcNick="$IrcNickb$((RANDOM%8388608))"
				echo "NICK $IrcNick" >&10
				for chan in "${IrcChans[@]}" ; do
					echo "JOIN $chan" >&10
				done
				;;
			QUIT)
				SrcNick="${src%%\!*}"
				logfile="$(date "+%Y/%m/%d").$FileExt"
				for chan in "${IrcChans[@]}" ; do
					tdir=${chan,,}
					mkdir -p "$Irclogdir/$tdir/${logfile%/*}"
					echo "$I$(date "+%X%z"): $B$SrcNick$B_ $command $target $args$I_" >> "$Irclogdir/$tdir/$logfile"
				done
				;;
			JOIN|PART)
				SrcNick="${src%%\!*}"
				logfile="$(date "+%Y/%m/%d").$FileExt"
				target="#${target#*#}" # To remove sometime f..k.ng mess before channel's name
				tdir=${target,,}
				mkdir -p "$Irclogdir/$tdir/${logfile%/*}"
				echo "$I$(date "+%X%z"): $B$SrcNick$B_ $command $target $args$I_" >> "$Irclogdir/$tdir/$logfile"
				;;
			NICK)
				SrcNick="${src%%\!*}"
				logfile="$(date "+%Y/%m/%d").$FileExt"
				for chan in "${IrcChans[@]}" ; do
					tdir=${chan,,}
					mkdir -p "$Irclogdir/$tdir/${logfile%/*}"
					echo "$I$(date "+%X%z"): $B$SrcNick$B_ is now know as $B$target$B_$I_" >> "$Irclogdir/$tdir/$logfile"
				done
				;;
			PRIVMSG|NOTICE)
				SrcNick="${src%%\!*}"
				if [[ "$target" == $IrcNick ]] ; then
					((!(RANDOM%4))) && echo "$(fortune)" | while read line ; do echo "PRIVMSG $SrcNick :$line" ; done >&10
				else
					logfile="$(date "+%Y/%m/%d").$FileExt"
					tdir=${target,,}
					mkdir -p "$Irclogdir/$tdir/${logfile%/*}"
					echo "$(date "+%X%z"): $B$SrcNick$B_ $args" >> "$Irclogdir/$tdir/$logfile"
				fi
				#echo "Message in main chan from $B$SrcNick$B_: $(echo "${args}" | hexdump -C)" >&2
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

