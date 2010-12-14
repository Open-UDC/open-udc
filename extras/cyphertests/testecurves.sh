#!/bin/bash

cypherlist="$(openssl ecparam -list_curves | grep : | while read line ; do echo -n "${line%%:*} " ; done)"

for ecname in $cypherlist ; do
	openssl ecparam -out "privkey_ec_$ecname.pem" -name "$ecname" -genkey
	openssl ec -in "privkey_ec_$ecname.pem" -pubout -outform DER > "pubkey_ec_$ecname"
done

openssl ecparam -list_curves | grep : | while read line ; do echo "$(wc -c pubkey_ec_${line%%:*}) ${line#*:} " ; done

