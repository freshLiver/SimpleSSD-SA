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

WORKLOAD_NAME="grep-many-512b"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

#
fsa_1k=(
    "241021-034953 -1024-x2000-3g-fsa"
    "241021-040411 -1024-x1500-3g-fsa"
    "241021-041838 -1024-x1000-3g-fsa"
    "241021-043327 -1024-x500-3g-fsa"
)
fsa_4k=(
    "241021-044839 -4096-x2000-3g-fsa"
    "241021-050555 -4096-x1500-3g-fsa"
    "241021-053612 -4096-x500-3g-fsa"
    "241021-064001 -4096-x1000-3g-fsa"
)
fsa_512b=(
    "241020-074904 -512-x2000-3g-fsa"
    "241020-080347 -512-x1500-3g-fsa"
    "241020-081832 -512-x1000-3g-fsa"
    "241020-083317 -512-x500-3g-fsa"
)
fsa_256b=(
    "241020-064908 -256-x2000-3g-fsa"
    "241020-070407 -256-x1500-3g-fsa"
    "241020-071855 -256-x1000-3g-fsa"
    "241020-073353 -256-x500-3g-fsa"
)

# fix prefetch, 1 isc core
fsa_1k_pft_1isc=(
    "241028-064302-1024- x2000-pft-1isc"
    "241028-070004-1024- x1500-pft-1isc"
    "241028-071418-1024- x1000-pft-1isc"
    "241028-072848-1024- x500-pft-1isc"
)
fsa_4k_pft_1isc=(
    "241028-074320- 4096-x2000-pft-1isc"
)
fsa_512b_pft_1isc=(
    "241028-083707- 512-x2000-pft-1isc"
)
fsa_256b_pft_1isc=(
    "241028-082135- 256-x2000-pft-1isc"
)

#
host_1k=(
    "241022-090854-1024- x2000-3g-host-o2"
    "241022-093232-1024- x1500-3g-host-o2"
    "241022-094916-1024- x1000-3g-host-o2"
    "241022-100517-1024- x500-3g-host-o2"
)
host_4k=(
    "241022-123747-4096- x2000-3g-host-o2"
    "241022-125645-4096- x1500-3g-host-o2"
    "241022-131602-4096- x1000-3g-host-o2"
    "241022-133320-4096- x500-3g-host-o2"
)
host_512b=(
    "241022-112741-512- x2000-3g-host-o2"
    "241022-114635-512- x1500-3g-host-o2"
    "241022-120431-512- x1000-3g-host-o2"
    "241022-122133-512- x500-3g-host-o2"
)
host_256b=(
    "241022-102033-256- x2000-3g-host-o2"
    "241022-103815-256- x1500-3g-host-o2"
    "241022-105536-256- x1000-3g-host-o2"
    "241022-111138-256- x500-3g-host-o2"
)

#
host_1k_pft_i1sc=(
    "241028-183342- 1024-x500-pft-1isc"
    "241028-185810- 1024-x2000-pft-1isc"
    "241028-191631- 1024-x1500-pft-1isc"
    "241028-193408- 1024-x1000-pft-1isc"
)
host_4k_pft_i1sc=(
    "241028-202730- 4096-x2000-pft-1isc"
)
host_512b_pft_i1sc=(
    "241028-200911- 512-x2000-pft-1isc"
)
host_256b_pft_i1sc=(
    "241028-195053- 256-x2000-pft-1isc"
)

#
slet_1k_pft_1isc=(
    "241028-090215-1024- x2000-pft-1isc"
    "241028-092013-1024- x1500-pft-1isc"
    "241028-093741-1024- x1000-pft-1isc"
    "241028-095427-1024- x500-pft-1isc"
)
slet_4k_pft_1isc=(
    "241028-101030- 4096-x2000-pft-1isc"
)
slet_256b_pft_1isc=(
    "241028-102823- 256-x2000-pft-1isc"
)
slet_512b_pft_1isc=(
    "241028-104601- 512-x2000-pft-1isc"
)

#
slet_1k=(
    "241023-052240-1024- x2000-3g-slet"
    "241023-054035-1024- x1500-3g-slet"
    "241023-060020-1024- x1000-3g-slet"
    "241023-061959-1024- x500-3g-slet"
)
slet_4k=(
    "241023-063442-4096- x2000-3g-slet"
    "241023-065127-4096- x1500-3g-slet"
    "241023-070747-4096- x1000-3g-slet"
    "241023-072350-4096- x500-3g-slet"
)
slet_256b=(
    "241022-054500-256- x2000-3g-slet"
    "241022-060218-256- x1500-3g-slet"
    "241022-061955-256- x1000-3g-slet"
    "241022-063651-256- x500-3g-slet"
)
slet_512b=(
    "241022-065235-512- x2000-3g-slet"
    "241022-071021-512- x1500-3g-slet"
    "241022-072726-512- x1000-3g-slet"
    "241022-074415-512- x500-3g-slet"
)


workloads=(
    # "host host_1k[@] *"
    # "host host_4k[@] *x2000*"
    # "host host_256b[@] *x2000*"
    # "host host_512b[@] *x2000*"

    # "host-pft-1isc host_1k_pft_i1sc[@] *  .debug"
    # "host-pft-1isc host_4k_pft_i1sc[@] *x2000*  .debug"
    # "host-pft-1isc host_256b_pft_i1sc[@] *x2000*  .debug"
    "host-pft-1isc host_512b_pft_i1sc[@] *x2000*  .debug"

    # "fsa fsa_1k[@] *"
    # "fsa fsa_4k[@] *x2000*"
    # "fsa fsa_512b[@] *x2000*"
    # "fsa fsa_256b[@] *x2000*"

    # "fsa-pft-1isc fsa_1k_pft_1isc[@] * .debug"
    # "fsa-pft-1isc fsa_4k_pft_1isc[@] *x2000* .debug"
    # "fsa-pft-1isc fsa_256b_pft_1isc[@] *x2000* .debug"
    "fsa-pft-1isc fsa_512b_pft_1isc[@] *x2000* .debug"

    # "slet slet_1k[@] *"
    # "slet slet_4k[@] *x2000*"
    # "slet slet_512b[@] *x2000*"
    # "slet slet_256b[@] *x2000*"

    # "slet-pft-1isc slet_1k_pft_1isc[@] * .debug"
    # "slet-pft-1isc slet_4k_pft_1isc[@] *x2000* .debug"
    # "slet-pft-1isc slet_256b_pft_1isc[@] *x2000* .debug"
    "slet-pft-1isc slet_512b_pft_1isc[@] *x2000* .debug"

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
