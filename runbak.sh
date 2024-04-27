#!/bin/bash
./build/simplessd-standalone ./config/sample.cfg ./simplessd/config/sample.cfg .

DIR=logs/`date +%y%m%d`

mkdir -p "$DIR"/stat
mkdir -p "$DIR"/debug

cp logs/stat.log "$DIR/stat/`date +%H%M%S`.log"
cp logs/debug.log "$DIR/debug/`date +%H%M%S`.log"
# cp logs/lats.log "$DIR/lats/`date +%H%M%S`.log"