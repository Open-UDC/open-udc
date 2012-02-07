#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

#set -x

# import modules
. ${0%/*}/ludd_init.env

function ludd_status {
    if [[ -d "$TmpDir" ]] ; then
    	if pidof "${0##*/}" ; then
    	    echo "STATUS: $0 is running (pids: $(cat "$TmpDir/pids"))"
    	    return
	fi

    	echo "STATUS: $0 seems dead but its working directory ($TmpDir) still exist"
    	return 2
    fi

    if pidof "${0##*/}" ; then
    	echo "STATUS: $0 is running but whithout its working directory (Oups !)"
    	return 2
    fi

    echo "STATUS: $0 is not running"
    return 1
}

function ludd_start {
    status="$(ludd_status $*)" # to avoid launching twice program
    case $? in
    	0)
    	    echo "$status"
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
    	    echo "$status"
    	    return 2
    	    ;;
    esac
}

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
	    ludd_status $*
    	    ;;
    	restart|reload)
    	    ;;
    	condrestart)
    	    ;;
    	*) # start
	    ludd_start $*
    	    ;;
    esac
}

# main program
ludd_init_build $*
ludd_main $*
exit $?
