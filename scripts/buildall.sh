#!/bin/bash

DEVICE_COUNT=2

if [ "$DEVBUILD" != "1" ]; then
    echo "CLEAN UP"
    cd $ANDROID_BUILD_TOP
    make clean
fi

for d in $(seq 1 $DEVICE_COUNT); do
    export OSARMOD_INIT=$d
    . $HOME/android/init.sh
    buildrom.sh
done

