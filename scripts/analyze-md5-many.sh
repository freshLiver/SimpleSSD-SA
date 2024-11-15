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
host_4k=(
    "241012-171735 x500-3g4k-host"
    "241012-173251 x1000-3g4k-host"
    "241012-174929 x1500-3g4k-host"
    "241012-180706 x2000-3g4k-host"
)
host_1k=(
    "241011-191122 x500-3g1k-host"
    "241011-192619 x1000-3g1k-host"
    "241011-194233 x1500-3g1k-host"
    "241011-195933 x2000-3g1k-host"
)
host_512b=(
    "241012-194158 x500-3g512b-host"
    "241012-195716 x1000-3g512b-host"
    "241012-202715 x2000-3g512b-host"
    "241014-114138 x1500-3g512b-host"
)
host_256b=(
    "241013-043256 x500-3g256b-host"
    "241013-044805 x1000-3g256b-host"
    "241013-050414 x1500-3g256b-host"
    "241013-051837 x2000-3g256b-host"
)

#
fsa_4k=(
    "241012-182604 x500-3g4k-fsa"
    "241012-184049 x1000-3g4k-fsa"
    "241012-185550 x1500-3g4k-fsa"
    "241012-191111 x2000-3g4k-fsa"
)
fsa_1k=(
    "241011-113359 x500-3g1k-fsa"
    "241011-114829 x1000-3g1k-fsa"
    "241011-120318 x1500-3g1k-fsa"
    "241011-121841 x2000-3g1k-fsa"
)
fsa_512b=(
    "241012-204447 x500-3g512b-fsa"
    "241012-205923 x1000-3g512b-fsa"
    "241012-212818 x2000-3g512b-fsa"
    "241014-112543 x1500-3g512b-fsa"
)
fsa_256b=(
    "241013-053621 x500-3g256b-fsa"
    "241013-055102 x1000-3g256b-fsa"
    "241013-060608 x1500-3g256b-fsa"
    "241013-062014 x2000-3g256b-fsa"
)

# fix prefetch, 1 isc core
fsa_1k_pft_1isc=(
    "241112-070515-1024- x2000-fsa-pft-isc1"
    "241112-072235-1024- x1500-fsa-pft-isc1"
    "241112-073903-1024- x1000-fsa-pft-isc1"
    "241112-075423-1024- x500-fsa-pft-isc1"
)
fsa_pft_1isc=(
    "241112-080939- 4096-x2000-fsa-pft-isc1"
    "241112-082553- 256-x2000-fsa-pft-isc1"
    "241112-084210- 512-x2000-fsa-pft-isc1"
)

##
slet_4k=(
    "241014-072613 x2000-3g4k-slet"
    "241014-074344 x1500-3g4k-slet"
    "241014-080047 x1000-3g4k-slet"
    "241014-081717 x500-3g4k-slet"
)
slet_1k=(
    "241014-124717 x2000-3g1k"
    "241014-130458 x1500-3g1k"
    "241014-132156 x1000-3g1k"
    "241014-133815 x500-3g1k"
)
slet_512b=(
    "241014-044216 x2000-3g512b-slet"
    "241014-051516 x1000-3g512b-slet"
    "241014-053135 x500-3g512b-slet"
    "241014-092335 x1500-3g512b-slet"
)
slet_256b=(
    "241014-055806 x2000-3g256b-slet"
    "241014-061625 x1500-3g256b-slet"
    "241014-063340 x1000-3g256b-slet"
    "241014-065002 x500-3g256b-slet"
)

#
slet_1k_pft_1isc=(
    "241112-100919-1024- x2000-slet-pft-isc1"
    "241112-102626-1024- x1500-slet-pft-isc1"
    "241112-104238-1024- x1000-slet-pft-isc1"
    "241112-105838-1024- x500-slet-pft-isc1"
)
slet_pft_1isc=(
    "241112-111356- 4096-x2000-slet-pft-isc1"
    "241112-113047- 256-x2000-slet-pft-isc1"
    "241112-114748- 512-x2000-slet-pft-isc1"
)


WORKLOAD_NAME="md5-many"
SRCDIR="$HOME/Dropbox/Notes/_david/research/logs/$WORKLOAD_NAME"
DSTDIR="workloads/$WORKLOAD_NAME"

workloads=(
    # "host host_1k[@] *"

    # "fsa fsa_1k[@] *"
    # "fsa fsa_4k[@] *x2000*"
    # "fsa fsa_512b[@] *x2000*"
    # "fsa fsa_256b[@] *x2000*"

    # "fsa-pft-1isc fsa_1k_pft_1isc[@] * .debug"
    "fsa-pft-1isc fsa_pft_1isc[@] *x2000* .debug"

    # "slet slet_1k[@] *"
    # "slet slet_4k[@] *x2000*"
    # "slet slet_512b[@] *x2000*"
    # "slet slet_256b[@] *x2000*"

    # "slet-pft-1isc slet_1k_pft_1isc[@] * .debug"
    "slet-pft-1isc slet_pft_1isc[@] *x2000* .debug"
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
