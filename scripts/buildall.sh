#!/bin/bash

case $OSARMOD_OS in
    cm9)
	DEVICE_START=1
	DEVICE_END=2
	;;
    cm10)
	DEVICE_START=3
	DEVICE_END=4
	;;
esac

if [ "$DEVBUILD" != "1" ]; then
    echo "CLEAN UP"
    cd $ANDROID_BUILD_TOP
    make clean
fi

for d in $(seq $DEVICE_START $DEVICE_END); do
    export OSARMOD_INIT=$d
    . $HOME/android/init.sh
    buildrom.sh
done

