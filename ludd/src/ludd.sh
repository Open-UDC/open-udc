#!/bin/bash

#set -x
. ${0%/*}/udini.env

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
                . common.env
                if UDDinit ; then
                    echo "starting creation daemon..."
                    ludcreationd.sh &
                    echo "starting peers discover (irc) daemon..."
                    ludpeersd.sh &
                    echo "starting authentication daemon..."
                    ludauthd.sh &
                    echo "starting database writer daemon..."
                    luddbd.sh &
                    echo "starting transaction daemon..."
                    ludtransactiond.sh &
                fi
                ;;
            *)
                echo "$sttus"
                return 2
                ;;
        esac
        ;;
esac
