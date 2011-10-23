#!/bin/bash

#set -x
. ${0%/*}/uset.env
UDinit
. ucreate.env
. udb.env
. umanage.env
. ugenid.env

while true ; do 
    udc_chooseinlist "Please choose what to do ?" 1 \
                     "Register your udid2 for Universal Monetary Dividend" \
                     "Register a new key for Universal Monetary Dividend" \
                     "Generate/Check an udid2" \
                     "Synchronyse Monetary creation" \
                     "Check the local balance of your account(s)" \
                     "Make and send a transaction" \
                     "Check if your receive new transaction(s)" \
                     "Validate a transaction file" \
                     "quit ${0##*/}" >&2
#"Update all database" \
    case $? in 
      1)
        # gpg --export ...
        echo "Sorry: Not implemented yet." >&2
        read -t 5
        ;;
      2)
        echo "Sorry: Not implemented yet." >&2
        read -t 5
        ;;
      3)
        UDgenudid
        read -t 5
        ;;
      4)
        UDsyncCreation
        ;;
      5)
        for account in "${myaccounts[@]}" ; do 
            echo -n "$account: "
            udc_freadbalance "$account"
        done
        read -t 5
        ;;
      6)
        if ((${#myaccounts[@]}>1)) ; then
            udc_chooseinlist "From which account ?" 1 "${myaccounts[@]}" >&2
            account="${myaccounts[$(($?-1))]}"
        else
            account="${myaccounts[0]}"
        fi
        read -p "How much ? " amount >&2
        grains=($(udc_preparetransaction $((amount)) "$account"))
        ret="$?"
        if ((ret==255)) ; then
            echo "Unknow error" >&2
        elif ((ret==254)); then
            echo "There is not enough money" >&2
        else
            if ((ret)) ; then
                read -p "we miss small grains to reach exactly the amount, do you want to continue (y/n) ? " rep >&2
                case "$rep" in
                  [yY]*)
                    ret=0
                  ;;
                  [nN]*) ;; #do Nothing
                  *) echo "  please answer \"yes\" or \"no\"" >&2 ;;
                esac
            fi
            if ((!ret)) ; then
                mapfile < <(sed -n ' s,^[[:xdigit:]]\{40\}:,,p ' "$udcHOME/$Currency/adressbook")
                udc_chooseinlist "To which account ?" 1 "${MAPFILE[@]}" # "Other..."
                destkey=$(sed -n "$?p" <(sed -n ' s,^\([[:xdigit:]]\{40\}\):.*,\1,p ' "$udcHOME/$Currency/adressbook"))
                #echo -n sended_amount
                echo "$account -> $destkey" >&2
                udc_maketransaction "$account" "$destkey" "${grains[@]}" >&2
                # Send it now ...
            fi
        fi
        ;;
      7)
        echo "Sorry: Not implemented yet." >&2
        read -t 5
        ;;
      8)
        read -p "filename ? " 
        UDvalidate "$REPLY"
        echo "function UDvalidate return $?"
        read -t 5
        ;;
      9)
        break
        ;;
      *)
        # should not happen 
        echo -e "Oups..." >&2
        break
        ;;
    esac
done
