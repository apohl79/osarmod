#!/bin/bash

VERSION_NAME=osar
BOOTIMG_DIR=$HOME/android/kernel/bootimg
BOOTIMG_OUT=$HOME/android/build
HELPER_DIR=$HOME/android/kernel/helper-files
KERNEL_DIR=$HOME/android/kernel/osarmod-cm-kernel
BUILD_DIR="$KERNEL_DIR/build"
MODULES=("drivers/net/wireless/bcm4329/bcm4329.ko" "fs/cifs/cifs.ko" "fs/fuse/fuse.ko" "drivers/net/tun.ko")
DATE=`date +%Y%m%d`
FLASH_ZIP="$BOOTIMG_OUT/kernel-osar"
INC=1

build ()
{
    local target=$1
    echo "-$VERSION_NAME-$DATE-$INC" > localversion
    #mv $KERNEL_DIR/drivers/video/samsung/logo_rgb24_wvga_portrait.h $KERNEL_DIR/drivers/video/samsung/logo_rgb24_wvga_portrait.h.org
    #cp $HELPER_DIR/logo/logo_rgb24_wvga_portrait.h $KERNEL_DIR/drivers/video/samsung/
    ./build.sh $target
    rm -f localversion
    #mv $KERNEL_DIR/drivers/video/samsung/logo_rgb24_wvga_portrait.h.org $KERNEL_DIR/drivers/video/samsung/logo_rgb24_wvga_portrait.h
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
    done

    echo "Creating CWM flashable zip for $target..."
    $ANDROID_BUILD_TOP/device/samsung/aries-common/mkshbootimg.py $BOOTIMG_DIR/boot.img "$target_dir"/arch/arm/boot/zImage $HELPER_DIR/ramdisk.img $HELPER_DIR/ramdisk-recovery.img
    cd $BOOTIMG_DIR
    zip -q -r $BOOTIMG_OUT/tmpupdate.zip .
    signzip $BOOTIMG_OUT/tmpupdate.zip $FLASH_ZIP 
    rm $BOOTIMG_OUT/tmpupdate.zip

    echo "DONE: $FLASH_ZIP"
}

target=galaxysmtd
if [ -n "$1" ] ; then
    target=$1
fi

FLASH_ZIP_T="$FLASH_ZIP-$target-$DATE-$INC-signed.zip"
while [ -e "$FLASH_ZIP_T" ]; do
    let INC++
    FLASH_ZIP_T="$FLASH_ZIP-$target-$DATE-$INC-signed.zip"
done
FLASH_ZIP=$FLASH_ZIP_T

cd $KERNEL_DIR
build $target
package $target
