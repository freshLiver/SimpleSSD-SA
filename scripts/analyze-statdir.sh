#!/bin/bash

ssfx=${1:-""}

function check_ret() {
    # Usage $? msg
    ret=$1
    if [[ $ret -ne 0 ]]; then
        echo "$2"
        exit $ret
    fi
}

WORKLOAD_NAME="statdir"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

fsa=(
    "240903-055017- d1-f1000-fix-lat"
    "240903-060745- d1-f2000-fix-lat"
    "240903-062515- d1-f4000-fix-lat"
    "240903-064658- d4-f1000-fix-lat"
    "240903-070437- d4-f2000-fix-lat"
    "240903-072225- d4-f4000-fix-lat"
)
host=(
    "240903-075024- d1-f1000-1g"
    "240903-080525- d1-f2000-1g"
    "240903-082104- d1-f4000-1g"
    "240903-083725- d4-f1000-1g"
    "240903-085339- d4-f2000-1g"
    "240903-091003- d4-f4000-1g"
)


workloads=(
    "host host[@] *"
    "fsa fsa[@] *"
)

for type_works in "${workloads[@]}"; do
    read type works filter <<< "$type_works"
    outdir="$DSTDIR/$type"

    # extract info from this type of workloads
    for work in "${!works}"; do
        read timestamp pfx <<< "$work"

        gem5LogFile="$SRCDIR/$type/$timestamp$pfx.log"
        hostLogFile="$SRCDIR/$type/$timestamp$pfx.host.log"
        if [[ ! -e "$gem5LogFile" || ! -e "$hostLogFile" ]]; then
            echo "Log file $gem5LogFile or $hostLogFile is missing"
            exit 1
        fi

        outfile="$outdir/$pfx.trace"
        mkdir -p "$outdir"

        # generate workload from gem5 logs
        bash "$(dirname $0)/gen-workload.sh" "$gem5LogFile" "$hostLogFile" > "$outfile"
        check_ret $? "Error during generating workload '$pfx'"

        echo "Workload file is saved at: $outfile"
    done

    # analyze workloads of this type
    "$(dirname $0)/run-workloads.sh" "$outdir/$filter" "$WORKLOAD_NAME-$type$ssfx"
    check_ret $? "Error during analyzing $type workloads"
done
