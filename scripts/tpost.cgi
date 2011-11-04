#!/bin/bash
echo -e  "Content-type: text/plain\n"

if [[ "$REQUEST_METHOD" != POST ]] ; then
 echo "Invalid HTTP METHOD" 
 exit 100 
fi
if ((CONTENT_LENGTH>=2048)) ; then 
 echo -e "Too many data"
 exit 101
fi

UDBot_fifo="/dev/shm/ludd.fifo"
if ! [[ -p "$UDBot_fifo" ]] ; then
 echo -e "OpenUDC validation deamon not available"
 exit 102
fi

filename="$(mktemp --tmpdir=/dev/shm/ tmpPOST.XXXX)"

mkfifo "$filename.fifo"

cat > "$filename"

echo "$filename.fifo $filename" >> "$UDBot_fifo"

cat "$filename.fifo" &

t=5
while jobs 1 > /dev/null && ((t--)) ; do
  sleep 1
done

if jobs 1 > /dev/null ; then
 kill -9 $!
# echo "TimeOut"
fi

rm -f "$filename.fifo" "$filename"

