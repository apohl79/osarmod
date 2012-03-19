#!/tmp/busybox sh
#
# CyanogenMod-7-RadioUpdater Script for Samsung Galaxy S Phones
# (c) 2011 by Teamhacksung
#

set -x
export PATH=/:/sbin:/system/xbin:/system/bin:/tmp:$PATH

if /tmp/busybox test -e /dev/block/mtdblock5 ; then
# we're running on a mtd device

    # create mountpoint for radio partition
    /tmp/busybox mkdir -p /radio
  
    # unmount radio partition
    /tmp/busybox umount -l /dev/block/mtdblock5

    # format radio partition
    /tmp/erase_image radio

    # mount radio partition and copy modem.bin
    if ! /tmp/busybox mount -t yaffs2 /dev/block/mtdblock5 /radio ; then
        exit 2
    else
        /tmp/busybox cp /tmp/modem.bin /radio/modem.bin
        /tmp/busybox chown radio:radio /radio/modem.bin
        /tmp/busybox chmod 0660 /radio/modem.bin
    fi
	
    # unmount radio partition
    /tmp/busybox umount -l /radio

    exit 0
else
    exit 1
fi
