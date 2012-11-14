#!/bin/bash

case $OSARMOD_OS in
    cm10)
	DEVICE_START=1
	DEVICE_END=2
	;;
esac

if [ "$1" != "-noclean" ]; then
    if [ "$DEVBUILD" != "1" ]; then
	echo "CLEAN UP"
	cd $ANDROID_BUILD_TOP
	make clean
    fi
fi

rm -f $HOME/android/releasebuild.log
for d in $(seq $DEVICE_START $DEVICE_END); do
    export OSARMOD_INIT=$d
    . $HOME/android/init.sh
    buildrom.sh 2>&1 | tee -a $HOME/android/releasebuild.log
done

