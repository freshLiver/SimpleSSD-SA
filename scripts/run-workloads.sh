#!/bin/bash
LOG_SUBDIR=$2
SA_CONF=${3:-"./config/sample.cfg"}
SSD_CONF=${4:-"./simplessd/config/sample.cfg"}
SA_BIN="./simplessd-standalone"

# ---------------------------------------------------------------------------- #
#                            check script arguments                            #
# ---------------------------------------------------------------------------- #

if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 WORKLOAD_FILES LOG_SUBDIR [SA_CONFIG [SSD_CONFIG]]]"
    exit 1
fi

# check workload exists
read WORKLOAD_FILES <<< $1
if [[ -z "$1" ]]; then
    echo "Invalid WORKLOAD_FILES"
    exit 1
fi
for workFile in ${WORKLOAD_FILES[@]}; do
    if [[ ! -e "$workFile" ]]; then
        echo "Workload file '$workFile' not exists"
        exit 1
    fi
done

# check log subdir
if [[ -z "$2" ]]; then
    echo "Invalid LOG_SUBDIR"
    exit 1
fi

# check simplessd configs
if [[ ! -e "$SA_CONF" ]]; then
    echo "Config file for SA not exists"
    echo "Expected path: $SA_CONF"
    exit 1
fi
if [[ ! -e "$SSD_CONF" ]]; then
    echo "Config file for SSD not exists"
    echo "Expected path: $SSD_CONF"
    exit 1
fi
if [[ ! -e "$SA_BIN" ]]; then
    echo "SA main program not exists!"
    echo "Expected path: $SA_BIN"
    exit 1
fi

# ---------------------------------------------------------------------------- #
#                             function definitions                             #
# ---------------------------------------------------------------------------- #

function ini_find() {
    # Usage: ini_content section key
    echo "$1" | awk "
    BEGIN { FOUND = 0; }
    \$1 ~ /^\[.*\]/ { FOUND = (\$1 == \"[$2]\" ? 1 : 0); }

    # find key
    FOUND == 1 && \$1 == \"$3\" {
        for (i=3; i<NF; ++i)
            printf \"%s \", \$i;
        print \$NF;
        exit;
    }
    "
}

function ini_update() {
    # Usage: ini_content section key new_vale
    echo "$1" | awk "
    BEGIN { FOUND_SECTION = 0; FOUND_KEY = 0; }
    \$1 ~ /^\[.*\]/ { FOUND_SECTION = (\$1 == \"[$2]\" ? 1 : 0); }

    # update value
    FOUND_SECTION == 1 && \$1 == \"$3\" { \$3 = \"$4\"; FOUND_KEY = 1; }
    FOUND_KEY == 0 { print }
    FOUND_KEY == 1 { printf \"%s = %s\n\", \$1, \$3; FOUND_KEY = 0; FOUND_SECTION = 0;}
    "
}

function repeat_char() {
    # Usage: char times
    printf "%${2}s" | tr ' ' "$1"
}

function print_text() {
    # Usage text indents
    folded=$(echo -e "$2" | fold -s -w 100)
    if [[ "$1" -ne 0 ]]; then
        tabs $(( 4 * $1 ))
        echo -e "$(echo $folded | sed -e 's/^/\t/g')\n\n"
    else
        echo -e "$folded\n\n"
    fi
    tabs 8 # reset tabs
}

LOG_BASEDIR="logs-sa"
LOG_PREFIX_STR='${LOG_BASEDIR}/${LOG_SUBDIR}/${LOG_PREFIX}'

STAT_LOG_SUFFIX="stat.txt"
DEBUG_LOG_SUFFIX="debug.log"
LAT_LOG_SUFFIX="lats.txt"

SIM_LOG_SUFFIX="sim.log"
SIM_CFG_SUFFIX="sim.cfg"
SIM_INPUT_SUFFIX="sim.input"
SIM_SUM_SUFFIX="sim-sum.txt"

function show_warnings() {
    echo -e "Warnings:\n"

    print_text 0 "The workload file should only contain the requests you want to replay. To extract the, an READ or ISC-INIT request will be automatically inserted as the first request, based on the workload type"
    print_text 1 "The updated workload file will be copied to '$LOG_PREFIX_STR.$SIM_INPUT_SUFFIX'"

    print_text 0 "For each workload, this script will change these SA configs (out-of-place updated):"
    print_text 1 "SA_CONFIG[global][LogFile] -> '$LOG_PREFIX_STR.$STAT_LOG_SUFFIX'"
    print_text 1 "SA_CONFIG[global][DebugLogFile] -> '$LOG_PREFIX_STR.$DEBUG_LOG_SUFFIX'"
    print_text 1 "SA_CONFIG[global][LatencyLogFile] -> '$LOG_PREFIX_STR.$LAT_LOG_SUFFIX'"
    print_text 1 "SA_CONFIG[trace][File] -> '\${TARGET_WORKLOAD_FILE}'"

    print_text 1 "The updated SA config file and other simulation outputs will be saved as '$LOG_PREFIX_STR.$SIM_CFG_SUFFIX', '$LOG_PREFIX_STR.$SIM_LOG_SUFFIX'"
}

LOG_PERIOD_MS_DEFAULT=100
function update_workload() {
    # Usage: simCfgFile simInputFile
    simCfg=$(cat "$1")
    simInputFile=$2

    # find LogPeriod, use default if not set
    msLogPeriod=$(ini_find "$simCfg" "global" "LogPeriod")
    if [[ -z "$msLogPeriod" ]]; then
        simCfg=$(ini_update "$simCfg" "global" "LogPeriod" "$LOG_PERIOD_MS_DEFAULT")
    fi
    sLogPeriod=$(echo "scale=3; $msLogPeriod * 0.001" | bc | awk '{ printf "%0.3f\n", $1}')

    # find time of the first request that matches the regex
    regex=$(ini_find "$simCfg" "trace" "Regex" | sed -E 's/^"(.*)"$/\1/g')
    if [[ -z "$regex" ]]; then
        print_text 0 "Invalid request time configuration"
        exit
    fi
    req1Time=$(grep -m1 -oP "$regex" "$simInputFile" | awk '{ print $1 }')

    # insert init request at $sLogPeriod secs before first request
    req0Time=$(echo "$req1Time - $sLogPeriod" | bc | awk '{printf "%0.12f", $0}')
    workType=$(awk '$2 ~ /S[SG]/ { printf "ISC"; exit; }' "$simInputFile")

    if [[ "$workType" == "ISC" ]]; then
        req0="SS 0x000000000000 + 0x1 AAAA"
    else
        req0="R 0x000000000000 + 0x1"
    fi
    sed -i "1s/^/$req0Time $req0\n/" "$simInputFile"
    if [[ "$?" -ne 0 ]]; then
        echo "Failed to update workload file"
        exit
    fi
}

function extract_beg_end_tick() {
    # Usage: $simLogFile

    # Because the SA simulator always adjusts the request issue time to speed up
    # simulation (check TraceReplayer::submitIO() for details), we cannot use
    # the request time defined in the workload file as begTick and endTick to
    # extract the needed range of debug logs.
    #
    # To address this problem, we can use the adjusted RECORD time from the
    # output of SA simulator ($simLogFile).
    #
    # However, in current implementation, the RECORD time only indicates when
    # the request is handled by the subsystem, instead of the real request issue
    # time. But this only make us miss some debug logs of the controller, which
    # is affordable in current needs.

    # extract time of records
    local records="$(grep -P "^RECORD: \d+\.\d+" "$1" | grep -oP '\d+\.\d+')"

    # find the second and last record
    local psRecords=($(sed -E 's/([0-9]+)\.([0-9]{12})/\1\2/g' <<< "$records"))
    local psRecord1=${psRecords[1]#0*}
    local psRecordN=${psRecords[-1]#0*}
    echo "$psRecord1 $psRecordN"
}

# ---------------------------------------------------------------------------- #
#                                  main logics                                 #
# ---------------------------------------------------------------------------- #

# run workloads
for workFile in ${WORKLOAD_FILES[@]}; do
    echo -e "\n$(repeat_char "-" 100)\n"

    work=$(basename $workFile)
    work=$(echo "${work%.*}")
    echo "Running workload: $workFile ('$work' in short)"

    # check the time in the workload are increasing

    # create workload related files
    LOG_DIR="$LOG_BASEDIR/$(date +%y%m)/$LOG_SUBDIR/$work"
    LOG_PREFIX="$(date +%d-%H%M%S)"
    mkdir -p "$LOG_DIR"
    echo "Log prefix: $LOG_SUBDIR/$work/$LOG_PREFIX"

    simLogFile="$LOG_DIR/$LOG_PREFIX.$SIM_LOG_SUFFIX"
    simCfgFile="$LOG_DIR/$LOG_PREFIX.$SIM_CFG_SUFFIX"
    simInputFile="$LOG_DIR/$LOG_PREFIX.$SIM_INPUT_SUFFIX"
    simSumFile="$LOG_DIR/$LOG_PREFIX.$SIM_SUM_SUFFIX"

    statLogFile="$LOG_DIR/$LOG_PREFIX.$STAT_LOG_SUFFIX"
    debugLogFile="$LOG_DIR/$LOG_PREFIX.$DEBUG_LOG_SUFFIX"
    latLogFile="$LOG_DIR/$LOG_PREFIX.$LAT_LOG_SUFFIX"


    # update workload and SA configs (make replicas and perform in-place update)
    cp "$SA_CONF" "$simCfgFile"
    cp "$workFile" "$simInputFile"

    ## update SA config
    simCfg=$(cat "$simCfgFile")
    simCfg=$(ini_update "$simCfg" "global" "LogFile" "$statLogFile")
    simCfg=$(ini_update "$simCfg" "global" "DebugLogFile" "$debugLogFile")
    simCfg=$(ini_update "$simCfg" "global" "LatencyLogFile" "$latLogFile")
    simCfg=$(ini_update "$simCfg" "trace" "File" "$simInputFile")
    echo "$simCfg" > "$simCfgFile"

    ## update workload
    update_workload "$simCfgFile" "$simInputFile"

    echo -e "\nChanges of SA Configs:"
    diff --color=always -B "$SA_CONF" "$simCfgFile"
    echo -e "\nChanges of workload:"
    diff --color=always -B "$workFile" "$simInputFile"

    # run workload
    trap exit SIGTERM SIGINT
    $SA_BIN $simCfgFile $SSD_CONF . &> "$simLogFile"
    echo -e "SimpleSSD-SA returned status: $? \n\n"

    # summarize this workload
    bash "$(dirname $0)/summarize-stat-log.sh" "$statLogFile" > "$simSumFile"

    read begTick endTick <<< "$(extract_beg_end_tick $simLogFile)"
    bash "$(dirname $0)/summarize-debug-log.sh" "$debugLogFile" "$begTick" "$endTick" >> "$simSumFile"
done
