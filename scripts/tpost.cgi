#!/bin/bash

if [[ "$REQUEST_METHOD" != POST ]] ; then
# echo -e  "Content-type: text/plain\n"
 echo -e "Content-type: text/udc-report;charset=UTF-8\n"
 echo "scode=400" 
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
#if ! [[ -p "$UDBot_fifo" ]] ; then
if false ; then
 echo -e "Content-type: text/udc-report;charset=UTF-8\n"
 echo "scode=000" 
 echo "sreport=\"OpenUDC deamon not available\""
 exit 102
fi

# Create a temporary file
filename="$(mktemp --tmpdir=/dev/shm/ tmpPOST.XXXX)"

case "${CONTENT_TYPE,,}" in 
 multipart/*|application/udc-*)
  echo "$CONTENT_TYPE" > "$filename" ;;
 *) # WTF has been send ??
  while read line ; do
   [[ "${line::13}" == "Content-Type:" ]] && break
  done
  if [[ "$line" ]] ; then 
   echo "$line" > "$filename"
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
# Copy input into the temporary file
cat > "$filename"

# Tell the daemon to manage this input
echo "$filename.fifo $filename" >> "$UDBot_fifo"

# And output its answer
cat "$filename.fifo" &
echo "$filename.fifo" >> "$filename.fifo"

# Max 5 second before timeout !
t=5
while jobs 1 > /dev/null && ((t--)) ; do
  sleep 1
done
if jobs 1 > /dev/null ; then
 kill -9 $!
# echo "TimeOut"
fi

rm -f "$filename.fifo" "$filename"

