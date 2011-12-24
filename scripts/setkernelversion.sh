#!/bin/bash

VER_FILE=$HOME/android/VERSION_KERNEL_$TARGET_PRODUCT
VER=$(cat $VER_FILE)

BASE=$(cat $VER_FILE|awk -F. '{print $1"."$2}')
BASE_NEW=$(date +%y.%m)
if [ "$BASE" = "$BASE_NEW" ]; then
    INC=$(cat $VER_FILE|awk -F. '{print $3}')
    let INC++
    VER_NEW="$BASE_NEW.$INC"
else
    VER_NEW="$BASE_NEW.1"
fi
echo $VER_NEW > $VER_FILE
