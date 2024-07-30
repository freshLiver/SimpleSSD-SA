#!/bin/bash

BegTick=$2
EndTick=$3

if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 LogFile BegTick EndTick"
    exit -1
fi

# Sample: "RECORD: 24.606908705795 R 0x000000011938 + 0x8 [B64 DATA]"

# remove leading hints and trailing spaces
records="$(grep "RECORD" $1 | sed -E 's/^RECORD: //g' | sed -E 's/ +$//g')"

# extract time formats
echo "$records" | sed -E 's/([0-9]+)\.([0-9]{12})/\1\2/g' | awk "
BEGIN {
    S = $BegTick
    E = $EndTick
    CNT = 0
}

S <= \$1 && \$1 <= E {
    print
    CNT += 1
}

END {
    printf \"# %d records are extracted\n\", CNT
}
"