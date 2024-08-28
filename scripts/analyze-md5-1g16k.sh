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

WORKLOAD_NAME="md5dir-1g16k"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

host_1g16k=(
    "240815-154454 x500-1g16k"
    "240815-160108 x1000-1g16k"
    "240815-161953 x1500-1g16k"
)
fsa_1g16k=(
    "240816-022642 x500-1g16k"
    "240816-024112 x1000-1g16k"
    "240816-025712 x1500-1g16k"
)
fsa_1g16k_d=(
    "240819-064710 x500-1g16k-dcache"
    "240819-070246 x1000-1g16k-dcache"
    "240819-071821 x1500-1g16k-dcache"
)



workloads=(
    # "host host_1g16k[@]"
    "fsa-d fsa_1g16k_d[@]"
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
