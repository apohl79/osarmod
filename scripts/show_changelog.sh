#!/bin/bash

TOP=$HOME/android/osarmod
VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
GIT_LOG=$TOP/files/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
CHANGELOG_NEW=$TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
CHANGELOG_TMP=/tmp/CHANGELOG_${OSARMOD_TYPE}

echo "ChangeLog" > $CHANGELOG_TMP
echo "=========" >> $CHANGELOG_TMP
if [ -e $CHANGELOG_NEW ]; then
    cat $CHANGELOG_NEW >> $CHANGELOG_TMP
fi
echo "" >> $CHANGELOG_TMP
echo "Git Changes" >> $CHANGELOG_TMP
echo "-----------" >> $CHANGELOG_TMP
git_changelog.pl $GIT_LOG $OSARMOD_DEVICE $OSARMOD_DEVICE_COMMON >> $CHANGELOG_TMP

cat $CHANGELOG_TMP

