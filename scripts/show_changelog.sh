#!/bin/bash

TOP=$HOME/android/osarmod
VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
GIT_LOG=$TOP/logs/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
GIT_KLOG=$TOP/logs/GIT_KLOG_${OSARMOD_TYPE}_$VERSION_NUM
CHANGELOG_NEW=$TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
CHANGELOG_TMP=/tmp/CHANGELOG_${OSARMOD_TYPE}
case $OSARMOD_TYPE in
    galaxysmtd-cm9)
	KERNEL_PATH=kernel/samsung/aries
	KERNEL_BRANCH=ics
	;;
esac

echo "ChangeLog" > $CHANGELOG_TMP
echo "=========" >> $CHANGELOG_TMP
if [ -e $CHANGELOG_NEW ]; then
    cat $CHANGELOG_NEW >> $CHANGELOG_TMP
fi
echo "" >> $CHANGELOG_TMP
echo "Git Changes" >> $CHANGELOG_TMP
echo "-----------" >> $CHANGELOG_TMP
if [ -n "$KERNEL_PATH" ]; then
    git_changelog.pl -b $KERNEL_BRANCH -d $KERNEL_PATH $GIT_KLOG >> $CHANGELOG_TMP
fi
if [ "$1" = "-nodevs" ]; then
    # use this for the sc alias, to see the changelog on the command line
    git_changelog.pl $GIT_LOG >> $CHANGELOG_TMP
else
    # at build time we just want to see the device's changes
    git_changelog.pl $GIT_LOG $OSARMOD_DEVICE $OSARMOD_DEVICE_COMMON >> $CHANGELOG_TMP
fi
cat $CHANGELOG_TMP

