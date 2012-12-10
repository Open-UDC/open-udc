#!/bin/bash

LOGFILE="/var/log/syslog"
MLIST="uni@lists.openudc.org"
MRLIST="uni-request@lists.openudc.org"
#SEND_ALL_TO="m@il.com"
#MYHOST="domesticserver.org:11371"
MYHOST="$(hostname):11371"
#KEYSERVER="hkp://pool.sks-keyservers.net"

yesterday=$(($(date +"%s")-86400))
yesterday="$(LC_ALL=C date -d@$yesterday +"%b %_d")"

nba=$(grep -h "^${yesterday}.*pks/add:accept:.*(udid2;c;" "$LOGFILE.1" "$LOGFILE" | wc -l)

if [ "$SEND_ALL_TO" ] ; then
	( echo -e "Subject: pks/add log report\n\n----- News -----\n" ;
	echo "Total with \"(udid2;c;...\": $nba"
	( grep -h "^${yesterday}.*pks/add:accept:" "$LOGFILE.1" "$LOGFILE"  | tee /dev/stderr 3>&1 1>&2 2>&3 | wc >&2 ) 2>&1
	echo -e "\n----- Updates -----\n"
	( grep -h "^${yesterday}.*pks/add:update:" "$LOGFILE.1" "$LOGFILE"  | tee /dev/stderr 3>&1 1>&2 2>&3 | wc >&2 ) 2>&1
	echo -e "\n----- Rejects -----\n"
	( grep -h "^${yesterday}.*pks/add:reject:" "$LOGFILE.1" "$LOGFILE"  | tee /dev/stderr 3>&1 1>&2 2>&3 | wc >&2 ) 2>&1
	) | sendmail "$SEND_ALL_TO"
fi

# Backup updated key(s) with effective change (without :0: before the fingerprint) to an other (sks) keyserver
[ "$KEYSERVER" ] && gpg --no-permission-warning --homedir /usr/local/var/ludd/gpgme/ --keyserver "$KEYSERVER" --send-keys $(sed -n " s,^${yesterday}.*pks/add:update:[^0][0-9]*:\([[:xdigit:]]\+\).*,\1,p " "$LOGFILE.1" "$LOGFILE" | sort | uniq ) &

# If there was no News keys with "(udid2;c;..." yesterday, exit now.
((nba)) || exit

# First extract the datas :
emails=($(sed -n " s,^${yesterday}.*pks/add:accept:.*(udid2;c;.*<\(.\+@.\+\)>:,\1\,,p " /var/log/syslog.1 /var/log/syslog))
eval news=($(sed -n " s,^${yesterday}.*pks/add:accept:[0-9]*:\([^<]*(udid2;c;[^<]\+\)<.*,\"\1\",p " "$LOGFILE.1" "$LOGFILE"))

# Backup new key(s) to an other (sks) keyserver
[ "$KEYSERVER" ] && gpg --no-permission-warning --homedir /usr/local/var/ludd/gpgme/ --keyserver "$KEYSERVER" --send-keys ${news[@]%%:*} &

if ((nba>1)) ; then
	subject="Subject: $nba new individual certificates to join our OpenUDC currency."
	message="
 We have received $nba new certificates which may signify that new individuals want to join our OpenUDC Currency.

 So we have to check that each person is the real onwer of the certificate and have correctly set their informations.
 In other words: owns the secret associated to the certificate, and have the good udid2 in it.

 That checking is normaly done during key signing parties http://en.wikipedia.org/wiki/Key_signing_party .
 But if you know personnaly the individuals indicated in new certificates, you also may call them to ask personnaly the fingerprint of their key and a copy of an id card or passport, then check, and sign the certificate if all is right.
 
 News certificates:"
else
	subject="Subject: a new individual certificate to join our OpenUDC currency"
	message="
 We have received a new certificate which may signify that a new individual wants to join our OpenUDC Currency.

 So we have to check that this person is the real onwer of the certificate and have correctly set their informations.
 In other words: owns the secret associated to the certificate, and have the good udid2 in it.

 That checking is normaly done during key signing parties http://en.wikipedia.org/wiki/Key_signing_party .
 But if you know personnaly the individual indicated below, you also may call her/him to ask personnaly the fingerprint of its key and a copy of its id card or passport, then check, and sign its certificate if all is right.
 
 The new certificate:"
fi

list="$(for i in ${!news[@]} ; do
	echo -e " * ${news[$i]#*:}\n\t To get it: http://$MYHOST/pks/lookup?op=get&search=0x${news[$i]%%:*}\n\t With gpg: $ gpg --keyserver \"hkp://$MYHOST\" --recv-keys ${news[$i]%%:*}\n"
	done)"

cat <<EOF | sendmail -f "$MLIST" -t
To: $MLIST
Cc: ${emails[@]}
$subject

$( echo -e "$message\n\n$list\n" | gpg --clearsign )

----
If you like to use the first OpenUDC currency, please stay subscribed to the uni currency mailing list.
EOF

# Send subcription for new emails
for i in ${!emails[@]} ; do
	echo -e "Subject: subscribe address=${emails[$i]%,}\n--" | sendmail -f "$MLIST" "$MRLIST"
done
