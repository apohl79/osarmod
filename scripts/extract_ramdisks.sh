#!/bin/bash

IN_DIR=$ANDROID_BUILD_TOP/out/target/product/galaxysmtd
OUT_DIR=$HOME/android/kernel/helper-files

echo "Extracting $IN_DIR/ramdisk.img to $OUT_DIR/ramdisk..."
mkdir $OUT_DIR/ramdisk
cd $OUT_DIR/ramdisk
gunzip -c $IN_DIR/ramdisk.img | cpio -i

echo "Extracting $IN_DIR/ramdisk-recovery.img to $OUT_DIR/ramdisk-recovery..."
mkdir $OUT_DIR/ramdisk-recovery
cd $OUT_DIR/ramdisk-recovery
gunzip -c $IN_DIR/ramdisk-recovery.img | cpio -i

echo "DONE"
