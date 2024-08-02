#!/bin/bash
statLogFile=$1
simSumFile=$2

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 statLogFile simSumFile"
    exit 1
fi

# init sum file
if [[ ! -e "$simSumFile" ]]; then
    touch "$simSumFile"
fi

# ---------------------------------------------------------------------------- #
#                                   functions                                  #
# ---------------------------------------------------------------------------- #

function stats_of_tick() {
    # Usage: statLogFile tick
    awk -v TARGET_TICK=$2 '
    BEGIN {
        TICK_BEG = 0
        TICK_END = 0
    }

    # end recording target section right now
    $0 ~ /^End of log @ tick/ && $6 == TARGET_TICK {
        TICK_END = 1
    }

    # content of stats
    TICK_BEG == 1 && TICK_END == 0 {
        printf "%s %s\n", $1, $2
    }

    # start recording target section from next line
    $0 ~ /^Periodic log printout @ tick/ && $6 == TARGET_TICK {
        TICK_BEG = 1
    }
    ' "$1"
}

function stat_find() {
    # Usage: stats key
    echo "$1" | grep -P "$2" | awk '{ print $2 }'
}

function ftoi() {
    # Usage: fp_value
    echo ${1%%.*}
}

function print_log() {
    # Usage: text
    echo -e "$1" | tee -a "$simSumFile"
}

function print_cores_time_diff() {
    # Usage: ArrRound0 ArrRoundN
    local -n ArrRound0=$1
    local -n ArrRoundR=$2

    for i in $(seq 1 ${#ArrRound0[@]}); do
        local i0=$(ftoi ${ArrRound0[$(($i - 1))]})
        local iN=$(ftoi ${ArrRoundR[$(($i - 1))]})
       print_log "\t[$(($i - 1))] = $(($iN - $i0)) ($iN - $i0)"
    done
}

# ---------------------------------------------------------------------------- #
#                                  main script                                 #
# ---------------------------------------------------------------------------- #

function main() {
    # extract stats of first round and last round
    local tickRound0=$(cat $statLogFile | grep -m1 "End of log @ tick" | awk '{print $6}')
    local tickRoundN=$(tac $statLogFile | grep -m1 "End of log @ tick" | awk '{print $6}')
    local statsRound0=$(stats_of_tick "$statLogFile" $tickRound0)
    local statsRoundN=$(stats_of_tick "$statLogFile" $tickRoundN)

    # Summarize I/O stats

    # 1. HIL
    print_log "\n@ HIL @\n"
    local numCmdsRound0=$(ftoi $(stat_find "$statsRound0" "command_count"))
    local numCmdsRoundN=$(ftoi $(stat_find "$statsRoundN" "command_count"))
    local numCmds=$(( $numCmdsRoundN - $numCmdsRound0 ))
    print_log "NVMe Requests = $numCmds ($numCmdsRoundN - $numCmdsRound0)"

    # 2. ICL
    print_log "\n@ ICL @\n"

    print_log "Busy Time (ps):"
    local psICLBusyRound0=($(stat_find "$statsRound0" "cpu\.icl\d\.busy"))
    local psICLBusyRoundN=($(stat_find "$statsRoundN" "cpu\.icl\d\.busy"))
    print_cores_time_diff psICLBusyRound0 psICLBusyRoundN


    # 3. FTL
    print_log "\n@ FTL @\n"

    print_log "Busy Time (ps):"
    local psFTLBusyRound0=($(stat_find "$statsRound0" "cpu\.ftl\d\.busy"))
    local psFTLBusyRoundN=($(stat_find "$statsRoundN" "cpu\.ftl\d\.busy"))
    print_cores_time_diff psFTLBusyRound0 psFTLBusyRoundN

    # 4. ISC
    print_log "\n@ ISC @\n"

    print_log "Busy Time (ps):"
    local psISCBusyRound0=($(stat_find "$statsRound0" "cpu\.isc\d\.busy"))
    local psISCBusyRoundN=($(stat_find "$statsRoundN" "cpu\.isc\d\.busy"))
    print_cores_time_diff psISCBusyRound0 psISCBusyRoundN


    # 5. NVM
    print_log "\n@ NVM @\n"

    local numNVMReadRound0=$(ftoi $(stat_find "$statsRound0" "pal\.read\.count"))
    local numNVMReadRoundN=$(ftoi $(stat_find "$statsRoundN" "pal\.read\.count"))
    local numNVMRead=$(( $numNVMReadRoundN - $numNVMReadRound0 ))

    local psNVMReadRound0=$(stat_find "$statsRound0" "pal\.read\.time\.total")
    local psNVMReadRoundN=$(stat_find "$statsRoundN" "pal\.read\.time\.total")

    local psNVMTotalReadRound0=$(echo "$numNVMReadRound0 * $psNVMReadRound0" | bc)
    local psNVMTotalReadRoundN=$(echo "$numNVMReadRoundN * $psNVMReadRoundN" | bc)
    local psNVMTotalRead=$(echo "$psNVMTotalReadRoundN - $psNVMTotalReadRound0" | bc)

    print_log "Read Count: $numNVMRead ($numNVMReadRoundN - $numNVMReadRound0)"
    print_log "Read Time: $psNVMTotalRead ($psNVMTotalReadRoundN - $psNVMTotalReadRound0) ps"
}

main