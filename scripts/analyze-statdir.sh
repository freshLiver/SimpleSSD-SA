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
    "241009-202008 -d1-f500-3g-fsa"
    "241009-203449 -d1-f1000-3g-fsa"
    "241009-204938 -d1-f2000-3g-fsa"
    "241009-210509 -d1-f4000-3g-fsa"
    "241009-212251 -d4-f500-3g-fsa"
    "241009-213717 -d4-f1000-3g-fsa"
    "241009-215208 -d4-f2000-3g-fsa"
    "241009-220746 -d4-f4000-3g-fsa"
)
host=(
    "241010-053959 -d1-f500-3g-host"
    "241010-055507 -d1-f1000-3g-host"
    "241010-061104 -d1-f2000-3g-host"
    "241010-062754 -d1-f4000-3g-host"
    "241010-064656 -d4-f500-3g-host"
    "241010-070211 -d4-f1000-3g-host"
    "241010-071744 -d4-f2000-3g-host"
    "241010-073500 -d4-f4000-3g-host"
)


workloads=(
    "host host[@] *"
    # "fsa fsa[@] *"
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
