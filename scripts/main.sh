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
                     "Change registered key for Universal Monetary Dividend" \
                     "Generate/Check an udid2" \
                     "Signalize a (living/deceased) individual" \
                     "Synchronyse Monetary creation" \
                     "Check the local balance of your account(s)" \
                     "Make and send a transaction" \
                     "Check if your receive new transaction(s)" \
                     "Validate a transaction file" \
                     "quit ${0##*/}" >&2
#"Update all database" \
#"Vouch (or no longer vouch) for someone else" \ 
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
        # What is its udid2 ?
        # When did you see this individual last time ?
        # Was she/he dead or alive ?
        # gpg --sign-key -N _dead@-=2011-10-24 -u mykey\! it's_udid2
        echo "Sorry: Not implemented yet." >&2
        read -t 5
        ;;
#      5)
#        # gpg --sign-key -N _alive@-=2011-10-24 -N '!Iam@voucher=2011-10-12' -u mykey\! it's_udid2
#        echo "Sorry: Not implemented yet." >&2
#        read -t 5
#        ;;
      5)
        UDsyncCreation
        ;;
      6)
      [[ "${myaccounts[0]}" ]] || echo "No account found."
        for account in "${myaccounts[@]}" ; do 
            echo -n "$account: "
            udc_freadbalance "$account"
        done
        read -t 5
        ;;
      7)
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
                echo "You miss small grains to reach exactly the amount,"
                if ((ret==253)) ; then 
                    read -p "  and will send at least $ret more, do you want to continue (y/n) ? " rep >&2
                else
                    read -p "  and will send $ret more, do you want to continue (y/n) ? " rep >&2
                fi
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
                udc_chooseinlist "To which account ?" 1 "${MAPFILE[@]}" "Other..."
                destkey=$(sed -n "$?p" <(sed -n ' s,^\([[:xdigit:]]\{40\}\):.*,\1,p ' "$udcHOME/$Currency/adressbook"))
                [[ "$destkey" ]] || read -p "Enter the fingerprint of destination account: " destkey >&2
                #echo -n sended_amount
                echo "$account -> $destkey" >&2
                if ! udc_maketransaction "$account" "$destkey" "${grains[@]}" >&2 ; then
                    echo "Making transaction failed. Return code = $? " >&2
                #else # Send it now ...
                fi
            fi
        fi
        ;;
      8)
        echo "Sorry: Not implemented yet." >&2
        read -t 5
        ;;
      9)
        read -p "filename ? " 
        UDvalidate "$REPLY"
        echo "function UDvalidate return $?"
        read -t 5
        ;;
      10)
        break
        ;;
      *)
        # should not happen 
        echo -e "Oups..." >&2
        break
        ;;
    esac
done
