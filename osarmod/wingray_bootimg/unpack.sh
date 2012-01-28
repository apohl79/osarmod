#!/bin/bash
# unpack boot.img
mkdir out
unpackbootimg -i boot.img -o out/
# unpack ramdisk
cd out
mkdir ramdisk
cd ramdisk
gunzip -c ../boot.img-ramdisk.gz | cpio -i

