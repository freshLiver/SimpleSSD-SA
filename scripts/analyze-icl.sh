#!/bin/bash
function analyze() {
    # usage: analyze $file $name
    BEG_TIME=$(grep "HIL: Runtime startSlet" "$1" | grep -oP "^\d+")
    BEG_TIME=${BEG_TIME:-0}
    CSV_DATA=$(grep "ICL::GenericCache: READ  | REQ" "$1" | awk "
        BEGIN { CNT = 0; print "$BEG_TIME"}
        {
            gsub(/:$/,\"\",\$1)

            addr = \$9
            stime = \$1
            if (strtonum(stime) >= $BEG_TIME) {
                printf \"$2,%d,%d,%d\n\", CNT,addr,stime
                CNT += 1
            }
        }
    ")
    echo "$CSV_DATA"
}

workloads=(
    # ALIAS PATH
    "gr-4k2k-f-p grep-fsa-1024x500-p.log"
    "gr-4k2k-f-np grep-fsa-1024x500-np.log"
)

NAMES=()
DATA=()
for work in "${workloads[@]}"; do
    read name file <<< "$work"
    NAMES+=("$name")
    DATA+="$(analyze "$file" "$name")"$'\n\n'
done

# echo "${NAMES[@]}"
echo "$DATA"
exit
