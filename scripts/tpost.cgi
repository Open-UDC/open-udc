#!/bin/bash

if [[ "$REQUEST_METHOD" != POST ]] ; then
# echo -e  "Content-type: text/plain\n"
 echo -e "Content-type: text/udc-report;charset=UTF-8\n"
 echo "scode=405" 
 echo "sreport=\"Invalid HTTP METHOD\"" 
 exit 100 
fi

#  if ((CONTENT_LENGTH>=4096)) ; then 
#   echo -e "Content-type: text/udc-report;charset=UTF-8\n"
#   echo -e "Too many data"
#   rm -f "$filename"
#   exit 101
#  fi

UDBot_fifo="/dev/shm/ludd.fifo"
if ! [[ -p "$UDBot_fifo" ]] ; then
#if false ; then
 echo -e "Content-type: text/udc-report;charset=UTF-8\n"
 echo "scode=503" 
 echo "sreport=\"OpenUDC deamon not available\""
 exit 102
fi

# Create a temporary file
filename="$(mktemp --tmpdir=/dev/shm/ tmpPOST.XXXX)"
# Note: filename is today not a fifo, to not slow/block the daemon which is not multithreaded (today with no lock on grain database).

case "${CONTENT_TYPE,,}" in 
 multipart/*|application/udc-*)
  echo -e "$CONTENT_TYPE\n" > "$filename" 
# Copy input into the temporary file
  head -c $CONTENT_LENGTH >> "$filename"
  ;;
 *) # WTF ?? search a line beginning with "Content-Type:" in the data.
  while read line ; do
   [[ "${line::13}" == "Content-Type:" ]] && found=1 && break
  done
  if ((found)) ; then 
   echo "$line" > "$filename"
# Copy input into the temporary file
   while read -t 1 line ; do 
    echo "$line" >> "$filename"
   done
  else
   echo -e "Content-type: text/udc-report;charset=UTF-8\n"
   echo "scode=400" 
   echo "sreport=\"Invalid input data\""
   rm "$filename" 
   exit 100 
  fi
  ;;
esac

# Create pipe were deamon will write its output
mkfifo "$filename.fifo"
chmod 664 "$filename.fifo"
# Tell the daemon to manage this input
echo "$filename.fifo $filename" >> "$UDBot_fifo"

# And output its answer
cat "$filename.fifo" &
#echo "$filename.fifo" >> "$filename.fifo"

# Max seconds before timeout !
t=30
while jobs 1 > /dev/null && ((t--)) ; do
  sleep 1
done
if jobs 1 > /dev/null ; then
 kill -9 $!
# echo "TimeOut"
fi

rm -f "$filename.fifo" "$filename"

