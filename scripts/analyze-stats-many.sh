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
host_32=(
    # "241206-120459- 4096-x2000-host-o2"
    "241206-122450- 256-x2000-host-o2"
    # "241206-124418- 512-x2000-host-o2"
)
host_64=(
    "241226-121636 -256-x2000-host-8m"
)

host_1k_32=(
    "240909-071240 x500-1k"
    "240909-073058 x1000-1k"
    "240909-075028 x1500-1k"
    "240909-081220 x2000-1k"
)
host_1k_64=(
)

#
fsa_1k_pft_1isc_32=(
)
fsa_1k_pft_1isc_64=(
    "241103-230747-1024- x2000-fsa-pft-isc1-b64"
    "241103-232309-1024- x1500-fsa-pft-isc1-b64"
    "241103-233820-1024- x1000-fsa-pft-isc1-b64"
    "241103-235335-1024- x500-fsa-pft-isc1-b64"
)
fsa_pft_1isc_32=(
    "241126-131635- 4096-x2000-b32-pft-1isc"
    "241126-133156- 256-x2000-b32-pft-1isc"
    "241126-134717- 512-x2000-b32-pft-1isc"
)
fsa_pft_1isc_64=(
    "241104-002811- 256-x2000-fsa-pft-isc1-b64"
    "241104-001039- 4096-x2000-fsa-pft-isc1-b64"
    "241104-004529- 512-x2000-fsa-pft-isc1-b64"
)

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

slet_1k_pft_1isc_32=(
    "241128-043628- 1024-x2000-slet-b32-pft-1isc"
    "241128-045337- 1024-x1500-slet-b32-pft-1isc"
    "241128-051018- 1024-x1000-slet-b32-pft-1isc"
    "241128-052633- 1024-x500-slet-b32-pft-1isc"
)
slet_1k_pft_1isc_64=(
    "241104-012435-1024- x2000-slet-pft-isc1-b64"
    "241104-014150-1024- x1500-slet-pft-isc1-b64"
    "241104-015839-1024- x1000-slet-pft-isc1-b64"
    "241104-021348-1024- x500-slet-pft-isc1-b64"
)
slet_pft_1isc_32=(
    "241128-054211- 4096-x2000-slet-b32-pft-1isc"
    "241128-055907- 256-x2000-slet-b32-pft-1isc"
    "241128-062657- 512-x2000-slet-b32-pft-1isc"
)
slet_pft_1isc_64=(
    "241104-024357- 256-x2000-slet-pft-isc1-b64"
    "241104-022837- 4096-x2000-slet-pft-isc1-b64"
    "241104-025927- 512-x2000-slet-pft-isc1-b64"
)

WORKLOAD_NAME="stats64-many"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

workloads=(
    # "host-o2 host_1k_32[@] *"
    # "host-o2 host_32[@] * .debug"
    "host-8m host_64[@] * .debug"

    # "fsa fsa_1k[@] *"
    # "fsa fsa_4k[@] *x2000*"
    # "fsa fsa_512b[@] *x2000*"
    # "fsa fsa_256b[@] *x2000*"

    # "fsa-1isc-pft-8m fsa_1k_pft_1isc_32[@] * .debug"
    # "fsa-1isc-pft-b32 fsa_pft_1isc_32[@] *x2000* .debug"
    # "fsa-pft-1isc fsa_1k_pft_1isc_64[@] * .debug"
    # "fsa-1isc-pft fsa_pft_1isc_64[@] *x2000* .debug"

    # "fsa-pft-1isc fsa_1k_pft_1isc_32[@] * .debug"
    # "fsa-pft-1isc fsa_pft_1isc_32[@] *x2000* .debug"

    # "slet slet_1k[@] *"
    # "slet slet_4k[@] *x2000*"
    # "slet slet_512b[@] *x2000*"
    # "slet slet_256b[@] *x2000*"

    # "slet-1isc-pft-b32 slet_1k_pft_1isc_32[@] * .debug"
    # "slet-1isc-pft-b32 slet_pft_1isc_32[@] *x2000* .debug"
    # "slet-pft-1isc slet_1k_pft_1isc_64[@] * .debug"
    # "slet-1isc-pft slet_pft_1isc_64[@] *x2000* .debug"

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
