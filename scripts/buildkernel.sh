#!/bin/bash

setkernelversion.sh

#MODEL=$(echo -n $TARGET_PRODUCT|sed 's/cyanogen_//'|sed 's/full_//')
case $OSARMOD_TYPE in
    galaxysmtd-cm7)
	MODEL=$OSARMOD_DEVICE
	KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
	BOOTIMG_DIR=$HOME/android/kernel/bootimg_$OSARMOD_TYPE
	MODULES=("drivers/net/wireless/bcm4329/bcm4329.ko" "fs/cifs/cifs.ko" "fs/fuse/fuse.ko" "drivers/net/tun.ko")
	;;
    galaxysmtd-cm9)
	MODEL=$OSARMOD_DEVICE
	KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
	BOOTIMG_DIR=$HOME/android/kernel/bootimg_$OSARMOD_TYPE
	#MODULES=$(cat $KERNEL_DIR/build/$OSARMOD_DEVICE/modules.order|sed 's#kernel/##')
	BRANCH=ics
	;;
    wingray-cm9)
	MODEL=stingray
	KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
	#MODULES=$(cat build/$OSARMOD_DEVICE/modules.order|sed 's#kernel/##')
	#MODULES=("drivers/scsi/scsi_wait_scan.ko")
	BRANCH=ics-xoom
	;;
    *)
	echo "TARGET_PRODUCT $TARGET_PRODUCT not supported"
	exit
	;;
esac

VERSION_NAME=osarmod
VERSION_NUM=`cat $HOME/android/osarmod/files/VERSION_KERNEL_$OSARMOD_TYPE`
BOOTIMG_OUT=$HOME/android/build/$OSARMOD_TYPE
ROMROOT_DIR=$HOME/android/osarmod/romroot
HELPER_DIR=$HOME/android/kernel/helper-files/$OSARMOD_TYPE
BUILD_DIR="$KERNEL_DIR/build"
FLASH_ZIP="$BOOTIMG_OUT/osarmod-$OSARMOD_OS-kernel"

function build() {
    export LOCALVERSION="-$VERSION_NAME-$VERSION_NUM"
    git co $BRANCH
     ./build.sh
}

function bootimg() {
    OUT=$1
    KERNEL=$2
    RAMDISK=$3
    RAMDISK_RECOVERY=$4
    case $OSARMOD_DEVICE in
	galaxysmtd)
	    $ANDROID_BUILD_TOP/device/samsung/aries-common/mkshbootimg.py $OUT $KERNEL $RAMDISK $RAMDISK_RECOVERY
	    ;;
	wingray)
	    $ANDROID_BUILD_TOP/out/host/linux-x86/bin/mkbootimg --kernel $KERNEL --ramdisk $RAMDISK --cmdline "androidboot.carrier=wifi-only product_type=w" --base 10000000 --pagesize 2048 -o $OUT
	    ;;
    esac
}

function package() {
    local target_dir=$KERNEL_DIR/build/$OSARMOD_DEVICE
    local modules=($(cat $KERNEL_DIR/build/$OSARMOD_DEVICE/modules.order|sed 's#kernel/##'))

    echo "Copying modules..."
    if [ ! -d $ROMROOT_DIR/$OSARMOD_TYPE/system/lib/modules ]; then
	mkdir -p $ROMROOT_DIR/$OSARMOD_TYPE/system/lib/modules
    else
	rm -f $ROMROOT_DIR/$OSARMOD_TYPE/system/lib/modules/*
    fi
    for module in "${modules[@]}" ; do
        cp "$target_dir/$module" $ROMROOT_DIR/$OSARMOD_TYPE/system/lib/modules
    done

    echo "Creating boot.img..."
    bootimg $ROMROOT_DIR/$OSARMOD_TYPE/boot.img "$target_dir"/arch/arm/boot/zImage $HELPER_DIR/ramdisk.img $HELPER_DIR/ramdisk-recovery.img

    echo "DONE: $ROMROOT_DIR/$OSARMOD_TYPE/boot.img"
}

FLASH_ZIP="$FLASH_ZIP-$MODEL-$VERSION_NUM-signed.zip"

cd $KERNEL_DIR
build
package
