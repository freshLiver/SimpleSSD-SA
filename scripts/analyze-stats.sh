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

WORKLOAD_NAME="stats"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

fsa=(
    "240907-102634- 1048576-test"
    "240907-104142- 262144-test"
    "240907-105630- 65536-test"
    "240907-111127- 16384-test"
    "240907-112627- 4096-test"
)
host=(
    "240907-152450- 1048576-test"
    "240907-154107- 262144-test"
    "240907-155719- 65536-test"
    "240907-161325- 16384-test"
    "240907-162919- 4096-test"
)
host3go2=(
    "240908-193528- 1048576-3go2"
    "240908-195131- 262144-3go2"
    "240908-200704- 65536-3go2"
    "240908-202251- 16384-3go2"
    "240908-203839- 4096-3go2"
)


workloads=(
    "host-3go2 host3go2[@] *"
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
