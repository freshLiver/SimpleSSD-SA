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

#
host_1k_32=()
host_1k_64=()

#
fsa_1k_32=()
fsa_1k_64=()

#
fsa_1k_pft_1isc_32=()
fsa_1k_pft_1isc_64=(
    "241103-230747-1024- x2000-fsa-pft-isc1-b64"
    "241103-232309-1024- x1500-fsa-pft-isc1-b64"
    "241103-233820-1024- x1000-fsa-pft-isc1-b64"
    "241103-235335-1024- x500-fsa-pft-isc1-b64"
)
fsa_pft_1isc_32=()
fsa_pft_1isc_64=()

#
slet_1k_32=(
    "241008-083617 x2000-3go2-1k-b32-slet"
    "241008-085241 x1500-3go2-1k-b32-slet"
    "241008-090843 x1000-3go2-1k-b32-slet"
    "241008-092437 x500-3go2-1k-b32-slet"
)
slet_1k_64=(
    "241007-111629 x2000-3go2-1k-b64-slet"
    "241007-113300 x1500-3go2-1k-b64-slet"
    "241007-114919 x1000-3go2-1k-b64-slet"
    "241007-120517 x500-3go2-1k-b64-slet"
)

slet_1k_pft_1isc_32=()
slet_1k_pft_1isc_64=(
    "241104-012435-1024- x2000-slet-pft-isc1-b64"
    "241104-014150-1024- x1500-slet-pft-isc1-b64"
    "241104-015839-1024- x1000-slet-pft-isc1-b64"
    "241104-021348-1024- x500-slet-pft-isc1-b64"
)
slet_pft_1isc_32=()
slet_pft_1isc_64=()

WORKLOAD_NAME="stats64-many-1k"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

workloads=(
    # "host host_1k[@] *"

    # "fsa fsa_1k[@] *"
    # "fsa fsa_4k[@] *x2000*"
    # "fsa fsa_512b[@] *x2000*"
    # "fsa fsa_256b[@] *x2000*"

    "fsa-pft-1isc fsa_1k_pft_1isc_64[@] * .debug"
    # "fsa-pft-1isc fsa_pft_1isc_64[@] *x2000* .debug"

    # "fsa-pft-1isc fsa_1k_pft_1isc_32[@] * .debug"
    # "fsa-pft-1isc fsa_pft_1isc_32[@] *x2000* .debug"

    # "slet slet_1k[@] *"
    # "slet slet_4k[@] *x2000*"
    # "slet slet_512b[@] *x2000*"
    # "slet slet_256b[@] *x2000*"

    "slet-pft-1isc slet_1k_pft_1isc_64[@] * .debug"
    # "slet-pft-1isc slet_pft_1isc_64[@] *x2000* .debug"

    # "slet-pft-1isc slet_1k_pft_1isc_32[@] * .debug"
    # "slet-pft-1isc slet_pft_1isc_32[@] *x2000* .debug"
)

for type_works in "${workloads[@]}"; do
    read type works filter sfx <<< "$type_works"
    outdir="$DSTDIR/$type"

    # extract info from this type of workloads
    for work in "${!works}"; do
        read timestamp pfx <<< "$work"

        gem5LogFile="$SRCDIR/$type/$timestamp$pfx$sfx.log"
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
