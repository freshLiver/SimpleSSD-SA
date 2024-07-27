#!/bin/bash
grep "RECORD" $1 | sed -E 's/^RECORD: //g' | sed -E 's/ +$//g'