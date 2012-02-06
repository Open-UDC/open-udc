#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

#set -x

# import modules
. ${0%/*}/ludd_init.env

function ludd_main {
    case "$1" in
	*h*)
	    echo "Usage: $0 {start|stop|restart|condrestart|status}"
	    ;;
	*v*)
	    echo "$luddVersion"
	    ;;
	stop)
	    ;;
	status)
	    if [[ -d "$TmpDir" ]] ; then
		if pidof "${0##*/}" ; then
		    echo "$0 is running (pids: $(cat "$TmpDir/pids"))"
		    return
		else
		    echo "$0 seems dead but its working directory ($TmpDir) still exist"
		    return 2
		fi
	    else
		if pidof "${0##*/}" ; then
		    echo "$0 is running but whithout its working directory (Oups !)"
		    return 2
		else
		    echo "$0 is not running"
		    return 1
		fi
	    fi
	    ;;
	restart|reload)
	    ;;
	condrestart)
	    ;;
	*) # start
	    sttus="$("$0" status)"
	    case $? in
		0)
		    echo "$sttus"
		    return
		    ;;
		1) #start
		    . lud_utils.env
		    if ludd_init ; then
			echo "starting creation daemon..."
			${0%/*}/ludd_creator.sh &
			echo "starting peers discover (irc) daemon..."
			${0%/*}/ludd_peers.sh &
			echo "starting authentication daemon..."
			#${0%/*}/ludd_authentication.sh &
			echo "starting database writer daemon..."
			#${0%/*}/ludd_db.sh &
			echo "starting transaction daemon..."
			#${0%/*}/ludd_transaction.sh &
		    fi
		    ;;
		*)
		    echo "$sttus"
		    return 2
		    ;;
	    esac
	    ;;
    esac
}

# main program
ludd_init_build $*
ludd_main $*
