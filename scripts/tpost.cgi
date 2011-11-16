#!/bin/bash
echo -e  "Content-type: text/plain\n"

# This cgi-script fast check than Post Data look like an OpenUDC Stream, then put its data in a file and ask for OpenUDC daemon to handle it.
if [[ "$REQUEST_METHOD" != POST ]] ; then
 echo "Invalid HTTP METHOD" 
 exit 100 
fi

if ! read -t 1 firstline ; then
 echo "OpenUDC:status:-4::TimeOut"
 exit 104
fi

if ! [[ "$firstline" =~ ^OpenUDC:..size:[0-9]+ ]] ; then
 echo "OpenUDC:status:-1::Unexpected Stream"
 exit 101
fi

UDBot_fifo="/dev/shm/ludd.fifo"
if ! [[ -p "$UDBot_fifo" ]] ; then
 echo "OpenUDC:status:-2::Validation deamon not available"
 exit 102
fi

if ((CONTENT_LENGTH>=2048)) ; then 
 echo "OpenUDC:status:-3::Too many data"
 exit 103
fi

filename="$(mktemp --tmpdir=/dev/shm/ tmpPOST.XXXX)"

mkfifo "$filename.fifo"

echo "$firstline" > "$filename"
cat >> "$filename"

echo "$filename.fifo $filename" >> "$UDBot_fifo"

cat "$filename.fifo" &

t=5
while jobs 1 > /dev/null && ((t--)) ; do
  sleep 1
done

if jobs 1 > /dev/null ; then
 kill -9 $!
# echo "OpenUDC:status:-4::TimeOut"
fi

rm -f "$filename.fifo" "$filename"

