#!/bin/bash

gem5LogFile=$1
hostLogFile=$2

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 gem5LogFile hostLogFile"
    exit -1
fi

# Since this script needs 2 arguments, it's not easy to generate workloads from
# multiple logs, you can write another script to call this script in loop
#
# Note that the hostLogFile must contain the information of begin/end tick in
# the format: 'Simulation Time: \d+~\d+ \(\d+\) ps'

if [[ ! -e "$1" ]]; then
    echo "The specified gem5LogFile '$1' not exists"
    exit -1
fi
if [[ ! -e "$2" ]]; then
    echo "The specified hostLogFile '$2' not exists"
    exit -1
fi

# extract beg/end tick from host log
psTimeInfo="$(grep -oP 'Simulation Time: \d+~\d+ \(\d+\) ps' $2)"
read psBegTick psEndTick <<< "$(grep -oP "\d+~\d+" <<< $psTimeInfo | tr '~' ' ')"
sBegTick=$(bc <<< "scale=12; $psBegTick / 10^12")
sEndTick=$(bc <<< "scale=12; $psEndTick / 10^12")

# extract records within target tick range from gem5LogFile
grep -P "^RECORD: \d+\.\d+" "$1" | awk -v S="$sBegTick" -v E="$sEndTick" '
BEGIN { CNT = 0 }

S <= $2 && $2 <= E {
    for (i = 2; i < NF; i++)
        printf "%s ", $i
    print $NF
    CNT += 1
}

END { printf "# %d records are extracted\n", CNT }
'