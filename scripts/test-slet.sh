#!/bin/bash

ID=$1
read -a KEYS <<< $2
read -a VALS <<< $3
RES_LBAS=$4

THIS_DIR="$(dirname $(realpath $0))"

if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 ID KEYS VALS RES_LBAS (10 key values at most)"
    exit -1
fi

# check #KEYS match #VALS
NR_KEYS=${#KEYS[@]}
NR_VALS=${#VALS[@]}

if [[ "$NR_KEYS" -ne "$NR_VALS" ]]; then
    echo "Expect NR_KEYS ($NR_KEYS) == NR_VALS ($NR_VALS)"
    exit -1
fi

function dec2hex() {
    echo 0x$(bc <<< "obase=16; $1")
}

function kv2b64() {
    tmpFile=$(mktemp -t sssa-test-slet.XXXXXXX.bin)
    keyLength=32
    valLengthMax=4096
    valLength=$(( ${#2} > $valLengthMax ? $valLengthMax : ${#2} ))

    srcKeyLength=${#1}
    srcValLength=${#2}
    padKeyLength=$(($keyLength - $srcKeyLength))
    padValLength=$(($valLength - $srcValLength))

    echo -n $1 > $tmpFile
    head -c $padKeyLength /dev/zero >> $tmpFile
    echo -n $2 >> $tmpFile
    head -c $padValLength /dev/zero >> $tmpFile

    # xxd $tmpFile
    B64_KV="$(base64 -w 0 $tmpFile)"
    B64_KV_SIZE=$(echo "$B64_KV" | wc -c)

    echo "$B64_KV_SIZE $B64_KV"
}

# ----------------------------------------------------------------


# write sample workload to file
TMP_FILE=$(mktemp -t sssa-test-slet.XXXXXXX)
echo -n "" > $TMP_FILE

# insert options: convert keys and values to isc-set requests
# isc-set format: 1.${ID}00000000000 SS 0x00020000000${ID} + 0x${DATA_LBAS_HEX} ${DATA_B64}
for i in $(seq 0 $(( $NR_KEYS - 1 ))); do
    # convert keys and values to request payload
    read DATA_SZ DATA_B64 <<< $(kv2b64 "${KEYS[$i]}" "${VALS[$i]}")
    echo "1.${i}00000000000 SS 0x00010000000${ID} + 0x1 ${DATA_B64}" >> $TMP_FILE

    # dump xxd for verification
    echo "KEY: '${KEYS[$i]}' VAL: '${VALS[$i]}'"
    base64 -d <<< "$DATA_B64" | xxd
done

# insert start-slet
echo "2.000000000000 SG 0x10000000000${ID} + 0x2" >> $TMP_FILE

# insert get-result-size
echo "3.000000000000 SG 0x00030000000${ID} + 0x8" >> $TMP_FILE

# insert get-result
echo "4.000000000000 SG 0x00020000000${ID} + $(dec2hex $RES_LBAS)" >> $TMP_FILE

cat $TMP_FILE
bash $THIS_DIR/run-workloads.sh $TMP_FILE "test-slet"

