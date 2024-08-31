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

WORKLOAD_NAME="md5dir-1g8k"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

host_1g8k=(
    "240815-083517 x500-1g8k"
    "240815-085244 x1000-1g8k"
    "240815-102911 x1500-1g8k"
)
fsa_1g8k=(
    "240815-105211 x500-1g8k"
    "240815-110733 x1000-1g8k"
    "240815-112243 x1500-1g8k"
)
fsa_1g8k_d=(
    "240821-112807x500-1g8k-dcache"
    "240821-114345x1000-1g8k-dcache"
    "240821-120007x1500-1g8k-dcache"
)

workloads=(
    # "host host_1g8k[@]"
    "fsa-d fsa_1g8k_d[@]"
)

for type_works in "${workloads[@]}"; do
    read type works <<< "$type_works"
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
    "$(dirname $0)/run-workloads.sh" "$outdir/*" "$WORKLOAD_NAME-$type$ssfx"
    check_ret $? "Error during analyzing $type workloads"
done
