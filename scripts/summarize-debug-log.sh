#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 File BegTick EndTick"
    exit 1
fi

FILE=$1
BegTick=$2
EndTick=$3

if [[ "$BegTick" -ge "$EndTick" ]]; then
    echo "BegTick (${BegTick}) must be less than EndTick (${EndTick})"
    exit 1
fi

# extract needed range
extract_tick_range_from_file() {
    if [ "$#" -ne 3 ]; then
        echo "Function Usage: $0 File BegTick EndTick"
        exit 1
    fi

    awk -v S="$2" -v E="$3" -F': ' '
    BEGIN {
        COUNT = 0
        LINE_NOW = 0
        LINE_FIRST_COUNT = -1
        LINE_LAST_COUNT = -1
    }

    {
        LINE = $0
        LINE_NOW += 1
    }

    COUNT > 0 && ($1 == "RECORD" || NF == 0) {
        LINE_LAST_COUNT = LINE_NOW
    }

    S <= $1 && $1 <= E {

        if (COUNT == 0)
            LINE_FIRST_COUNT = LINE_NOW
        COUNT += 1

        print

        if ((LINE_LAST_COUNT != -1) && (LINE_NOW - 1 != LINE_LAST_COUNT)) {
            printf "\nERROR: Unexpected line in (%d,%d)\n", LINE_LAST_COUNT, LINE_NOW | "cat 1>&2"
            exit -1
        }
        LINE_LAST_COUNT = LINE_NOW
    }

    END {
        printf "%d lines in [%d,%d]\n\n", COUNT, LINE_FIRST_COUNT, LINE_LAST_COUNT | "cat 1>&2"
    }
    ' "$1"
}

lats_no_overlap() {
    local LAT_RANGES="$1"

    # clear tmp file
    local LATS_TMP_FILE="/tmp/sss-lat-stat-tmp.txt"
    echo -n "" > "$LATS_TMP_FILE"

    # add suffix to time ranges and sort them
    while IFS= read -r lat; do
        read -a tokens <<< "$lat"
        echo -e "${tokens[0]}S\n${tokens[2]}E" >> "$LATS_TMP_FILE"
    done <<< "$LAT_RANGES"

    local LATS_NO_OVERLAP=$(cat "${LATS_TMP_FILE}" | sort | awk '
    {
        time = substr($0, 1, length($0)-1)  # get time
        type = substr($0, length($0))       # get S/E

        if (type == "S") {
            if (start == 0) {
                start = time
            }
            count++
        } else if (type == "E") {
            count--
            if (count == 0) {
                total += time - start
                start = 0
            }
        }
    }
    END {
        print total
    }
    ' -)
    echo -e "\tTotal latency: ${LATS_NO_OVERLAP} ps (no overlap)"
}

lats_summary() {
    if [ $# -ne 3 ]; then
        echo "Usage: $0 LAYER FMT RAW_STATS"
        exit -1
    fi

    local LATS_BASE=$(echo "$3" | grep -P "$2")
    local LATS_NR=$(echo "$LATS_BASE" | wc -l)

    echo "$1"
    echo -e "\tThere are ${LATS_NR} accesses"

    if [ "$1" == "NVM" ]; then
        echo -e "\tTotal latency: N/A (don't know MSB/LSB access ratio)"
    elif [ "$1" == "ISC" ]; then
        echo -e "\tTotal latency: N/A (no latency info yet)"
    else
        local DIFFS=$(echo "$LATS_BASE" | grep -oP "\(\d+\)$" | grep -oP "\d+")
        local RANGES=$(echo "$LATS_BASE" | grep -oP "\d+ \- \d+")

        echo -e "\tTotal latency: $(echo "$DIFFS" | paste -sd+ | bc) ps"
        lats_no_overlap "$RANGES"

        # ICL need more info
        if [ "$1" == "ICL" ]; then
            # cache hit rate
            local HITS=$(echo "$LATS_BASE" | grep "Cache hit" | wc -l)
            local RATE=$(echo "scale=4; ${HITS} / ${LATS_NR}" | bc)
            echo -e "\n\tHit rate: ${RATE} (${HITS}/${LATS_NR})"

            # access sizes
            echo "$3" | grep -P "GenericCache.*SIZE \d+$" | grep -oP "SIZE \d+$" | awk '
                { size[$2] += 1 }
                END {
                    for (s in size)
                        printf "\t\t\t%d Byte x %d\n", s, size[s]
                }
            '
        fi
    fi

}

# Extract needed lines
LATS_RANGE="$(extract_tick_range_from_file "$FILE" $BegTick $EndTick)"
if [ $? -ne 0 ]; then
    exit -1
fi

# HIL
HIL_LAT_MAIN_FMT="HIL::NVMe: NVM     \|[ \-A-Za-z0-9]+\| .* \d+ - \d+ \(\d+\)$"
lats_summary "HIL" "$HIL_LAT_MAIN_FMT" "$LATS_RANGE"


# ICL
ICL_LAT_MAIN_FMT="ICL::GenericCache: READ  \| Cache .* \d+ - \d+ \(\d+\)$"
lats_summary "ICL" "$ICL_LAT_MAIN_FMT" "$LATS_RANGE"


# FTL
FTL_LAT_MAIN_FMT="FTL::PageMapping: READ  \| LPN"
lats_summary "FTL" "$FTL_LAT_MAIN_FMT" "$LATS_RANGE"


# NVM
NVM_LAT_MAIN_FMT="PAL::PALOLD: READ  \| Block"
lats_summary "NVM" "$NVM_LAT_MAIN_FMT" "$LATS_RANGE"


# ISC
ISC_LAT_MAIN_FMT="ISC::.*: applyLatency"
lats_summary "ISC" "$ISC_LAT_MAIN_FMT" "$LATS_RANGE"