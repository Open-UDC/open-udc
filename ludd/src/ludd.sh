#!/bin/bash

#set -x
. ${0%/*}/udini.env
. common.env
UDDinit
. uddb.env
. udcreate.env
. uvalidation.env

case $1 in 
    *h*)
        echo "Usage: $0 {start|stop|restart|condrestart|status}"
        ;;
    *v*)
        echo "$luddVersion"
        ;;
    stop)
        ;;
    status)
        ;;
    restart|reload)
        ;;
    condrestart)
        ;;
    *) # start
        ;;
esac
