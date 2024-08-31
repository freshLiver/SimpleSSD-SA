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

WORKLOAD_NAME="md5dir-1g4k"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

host_1g4k=(
    "240814-090025 x100-1g4k"
    "240814-091555 x500-1g4k"
    "240814-093112 x1000-1g4k"
    "240814-094738 x2000-1g4k"
    "240814-100618 x4000-1g4k"
)
fsa_1g4k=(
    "240814-112259 x100-1g4k"
    "240814-113809 x500-1g4k"
    "240814-115259 x1000-1g4k"
    "240814-120809 x2000-1g4k"
    "240814-122443 x4000-1g4k"
)
fsa_1g4k_d=(
    # "240819-110318 x100-1g4k-dcache"
    # "240819-101125 x500-1g4k-dcache"
    # "240819-102613 x1000-1g4k-dcache"
    "240819-104224 x1500-1g4k-dcache"
    # "240819-111905 x2000-1g4k-dcache"
    # "240819-113516 x4000-1g4k-dcache"
)


workloads=(
    # "fsa fsa_1g4k[@] *"
    "fsa-d fsa_1g4k_d[@] *x1500*"
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
