#!/bin/bash

DIR=$HOME/android/kernel/helper-files

echo "Creating $DIR/ramdisk.img..."
cd $DIR/ramdisk
find . | cpio -o -H newc | gzip > $DIR/ramdisk.img

echo "Creating $DIR/ramdisk-recovery.img..."
cd $DIR/ramdisk-recovery
find . | cpio -o -H newc | gzip > $DIR/ramdisk-recovery.img

echo "DONE"
