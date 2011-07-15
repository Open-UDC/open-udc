#!/bin/bash

SW="OpenUDC"
Version="ugen_udid.sh ($SW) 0.0.1 - devel"

# translate long options to short
# Note: This enable long options but disable "--?*" in $OPTARG, or disable long options after  "--" in option fields.
for ((i=1;$#;i++)) ; do
    case "$1" in
        --) 
            # [ ${args[$((i-1))]} == ... ] || EndOpt=1 ;;& # DIRTY: we still can handle some execptions...
            EndOpt=1 ;;&
        --version) ((EndOpt)) && args[$i]="$1"  || args[$i]="-V";; 
        # default case : short option use the first char of the long option:
        --?*) ((EndOpt)) && args[$i]="$1"  || args[$i]="-${1:2:1}";;
        # pass through anything else:
        *) args[$i]="$1" ;;
    esac
    shift
done
# reset the translated args
set -- "${args[@]}"

function usage {
echo "Usage: $0 [options] files" >&2
    exit $1
}

# now we can process with getopt
while getopts ":hvVc:" opt; do
    case $opt in
        h)  usage ;;
        v)  VERBOSE=true ;;
        V)  echo $Version ; exit ;;
        c)  source $OPTARG ;;
        \?) echo "unrecognized option: -$opt" ; usage -1 ;;
        :)
        echo "option -$OPTARG requires an argument"
        usage -1
        ;;
    esac
done

shift $((OPTIND-1))
[[ "$1" == "--" ]] && shift

