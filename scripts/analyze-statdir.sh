#!/bin/bash

SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/statdir"
DSTDIR="workloads/statdir"

workloads=(
    "fsa 240809-135508- d1-f1000"
    "fsa 240809-141027- d1-f2000"
    "fsa 240809-142655- d1-f4000"
    "fsa 240809-144501- d4-f1000"
    "fsa 240809-145959- d4-f2000"
    "fsa 240809-151650- d4-f4000"
    # "host 240807-113403- d1-f1000"
    # "host 240807-114938- d1-f2000"
    # "host 240807-120424- d1-f4000"
    # "host 240807-121955- d4-f1000"
    # "host 240807-123516- d4-f2000"
    # "host 240807-125007- d4-f4000"
)

function check_ret() {
    # Usage $? msg
    ret=$1
    if [[ $ret -ne 0 ]]; then
        echo "$2"
        exit $ret
    fi
}

for work in "${workloads[@]}"; do
    read type timestamp pfx <<< "$work"

    gem5LogFile="$SRCDIR/$type/$timestamp$pfx.log"
    hostLogFile="$SRCDIR/$type/$timestamp$pfx.host.log"

    outdir="$DSTDIR/$type"
    outfile="$outdir/$pfx.trace"
    mkdir -p "$outdir"

    # generate workload from gem5 logs
    bash "$(dirname $0)/gen-workload.sh" "$gem5LogFile" "$hostLogFile" > "$outfile"
    check_ret $? "Error during generating workload '$pfx'"

    echo "Workload file is saved at: $outfile"
done

# analyze workload with SA
types=("fsa")
for type in "${types[@]}"; do
    outdir="$DSTDIR/$type"

    "$(dirname $0)/run-workloads.sh" "$outdir/*" "statdir-$type"
    check_ret $? "Error during analyzing $type workloads"
done