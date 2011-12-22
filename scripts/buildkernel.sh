#!/bin/bash

setkernelversion.sh

VERSION_NAME=osarmod
VERSION_NUM=`cat $HOME/android/VERSION_KERNEL`
BOOTIMG_DIR=$HOME/android/kernel/bootimg
BOOTIMG_OUT=$HOME/android/build
ROMROOT_DIR=$HOME/android/romroot
HELPER_DIR=$HOME/android/kernel/helper-files
KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
BUILD_DIR="$KERNEL_DIR/build"
MODULES=("drivers/net/wireless/bcm4329/bcm4329.ko" "fs/cifs/cifs.ko" "fs/fuse/fuse.ko" "drivers/net/tun.ko")
FLASH_ZIP="$BOOTIMG_OUT/osarmod-cm7-kernel"

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
        cp "$target_dir/$module" $ROMROOT_DIR/$target/system/lib/modules
    done

    echo "Creating CWM flashable zip for $target..."
    $ANDROID_BUILD_TOP/device/samsung/aries-common/mkshbootimg.py $BOOTIMG_DIR/boot.img "$target_dir"/arch/arm/boot/zImage $HELPER_DIR/ramdisk.img $HELPER_DIR/ramdisk-recovery.img
    cd $BOOTIMG_DIR
    cp boot.img $ROMROOT_DIR/$target
    zip -q -r $BOOTIMG_OUT/tmpupdate.zip .
    signzip $BOOTIMG_OUT/tmpupdate.zip $FLASH_ZIP 
    rm $BOOTIMG_OUT/tmpupdate.zip

    echo "DONE: $FLASH_ZIP"
}

target=galaxysmtd
if [ -n "$1" ] ; then
    target=$1
fi

FLASH_ZIP="$FLASH_ZIP-$target-$VERSION_NUM-signed.zip"

cd $KERNEL_DIR
build $target
package $target
