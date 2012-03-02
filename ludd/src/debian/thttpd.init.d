#!/bin/sh

### BEGIN INIT INFO
# Provides:          thttpd
# Required-Start:    $network
# Required-Stop:     $network
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Starts tiny/turbo/throttling HTTP server
# Description:       thttpd is a small, fast secure webserver.
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/thttpd
DESC="web server"
NAME=thttpd

CONFFILE=/etc/thttpd/thttpd.conf
PIDFILE=/var/run/thttpd.pid
OPTIONS="-C $CONFFILE -i $PIDFILE"

test -x $DAEMON || exit 0
test -f $CONFFILE || exit 1

set -e

case "$1" in
	start)
		echo -n "Starting $DESC: "
		start-stop-daemon -S -q -p $PIDFILE -x $DAEMON -- $OPTIONS
		echo "$NAME."
		;;

	stop)
		echo -n "Stopping $DESC: "

		if ps ax | grep "$(cat $PIDFILE)" | grep -qv grep
		then
			start-stop-daemon -K -q -p $PIDFILE -x $DAEMON --signal 10
		fi

		echo "$NAME."
		;;

	force-stop)
		echo -n "Stopping $DESC: "
		start-stop-daemon -K -q -p $PIDFILE -x $DAEMON
		echo "$NAME."
		;;

	force-reload)
		if start-stop-daemon -K -q -p $PIDFILE -x $DAEMON --test
		then
			$0 restart
		fi
		;;

	restart)
		echo -n "Restarting $DESC: "
		start-stop-daemon -K -q -p $PIDFILE -x $DAEMON --signal 10
		sleep 1
		start-stop-daemon -S -q -p $PIDFILE -x $DAEMON -- $OPTIONS
		echo "$NAME."
		;;

	*)
		N=/etc/init.d/$NAME
		echo "Usage: $N {start|stop|force-stop|restart|force-reload}" >&2
		exit 1
		;;
esac

exit 0
