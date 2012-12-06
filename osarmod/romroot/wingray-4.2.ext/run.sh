#!/bin/bash

# copy recovery image
cp $OUT/recovery.img $REPACK

# update updater-script
SCRIPT=$REPACK/META-INF/com/google/android/updater-script
cat $SCRIPT | sed 's#format("ext4", "EMMC", "/dev/lvpool/system", "-4096", "/system");#run_program("/sbin/mkfs.ext2", "-b", "4096", "/dev/lvpool/system");#' > $SCRIPT.new
echo 'package_extract_file("recovery.img", "/dev/block/platform/sdhci-tegra.3/by-name/recovery");' >> $SCRIPT.new
mv $SCRIPT.new $SCRIPT
