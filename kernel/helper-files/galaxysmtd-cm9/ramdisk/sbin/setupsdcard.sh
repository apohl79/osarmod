#!/system/bin/sh
#
# 2012-03-10 Andreas Pohl
#
# Setup the correct vold.fstab based on user settings:
#   1) Check if the file /data/local/switch_sdcard exists
#   a) The file exists: use /system/etc/vold.fstab.ext to mount the external sdcard to /mnt/sdcard
#   b) Else: use /system/vold.fstab.int to mount the internal sdcard to /mnt/sdcard

if test -e /data/local/switch_sdcard; then
    /system/xbin/busybox cp /system/etc/vold.fstab.ext /system/etc/vold.fstab
else
    /system/xbin/busybox cp /system/etc/vold.fstab.int /system/etc/vold.fstab
fi
