#!/bin/bash

setkernelversion.sh

#MODEL=$(echo -n $TARGET_PRODUCT|sed 's/cyanogen_//'|sed 's/full_//')
MODEL=$OSARMOD_DEVICE
case $OSARMOD_TYPE in
    galaxysmtd-cm7)
	KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
	BOOTIMG_DIR=$HOME/android/kernel/bootimg
	MODULES=("drivers/net/wireless/bcm4329/bcm4329.ko" "fs/cifs/cifs.ko" "fs/fuse/fuse.ko" "drivers/net/tun.ko")
	;;
    galaxysmtd-cm9)
	KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
	BOOTIMG_DIR=$HOME/android/kernel/bootimg
	MODULES=("fs/cifs/cifs.ko" "fs/fuse/fuse.ko" "fs/nls/nls_utf8.ko")
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
HELPER_DIR=$HOME/android/kernel/helper-files
BUILD_DIR="$KERNEL_DIR/build"
FLASH_ZIP="$BOOTIMG_OUT/osarmod-$OSARMOD_OS-kernel"

build ()
{
    local target=$1
    export LOCALVERSION="-$VERSION_NAME-$VERSION_NUM"
     ./build.sh $target
}

package ()
{
    local target=$1
    local target_dir="$BUILD_DIR/$target"

    if [ "$target" = "clean" ]; then
	return
    fi

    echo "Copying modules for $target..."
    for module in "${MODULES[@]}" ; do
        cp "$target_dir/$module" $BOOTIMG_DIR/system/lib/modules
        cp "$target_dir/$module" $ROMROOT_DIR/$OSARMOD_TYPE/system/lib/modules
    done

    echo "Creating CWM flashable zip for $target..."
    $ANDROID_BUILD_TOP/device/samsung/aries-common/mkshbootimg.py $BOOTIMG_DIR/boot.img "$target_dir"/arch/arm/boot/zImage $HELPER_DIR/ramdisk.img $HELPER_DIR/ramdisk-recovery.img
    cd $BOOTIMG_DIR
    cp boot.img $ROMROOT_DIR/$OSARMOD_TYPE
    zip -q -r $BOOTIMG_OUT/tmpupdate.zip .
    signzip $BOOTIMG_OUT/tmpupdate.zip $FLASH_ZIP 
    rm $BOOTIMG_OUT/tmpupdate.zip

    echo "DONE: $FLASH_ZIP"
}

FLASH_ZIP="$FLASH_ZIP-$MODEL-$VERSION_NUM-signed.zip"

cd $KERNEL_DIR
build $MODEL
package $MODEL
