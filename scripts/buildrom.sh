#!/bin/bash

MAILTO=ap@diepohls.com
TOP=$HOME/android/osarmod
ROMROOT=$TOP/romroot
MODEL=$OSARMOD_DEVICE

echo -ne "\033]0;[Building] $OSARMOD_TYPE ...\007"

#
# INITIALIZATION
#
SIZE_CHECK=1
case $OSARMOD_TYPE in
    galaxysmtd-cm9)
	echo "Generating kernel changelog..."
	cd kernel/samsung/aries
	git_changelog.pl > /tmp/GIT_KLOG
	cd -
	SIZE_CHECK=0
	;;
    galaxysmtd-cm10)
	SIZE_CHECK=0
	;;
    wingray-cm10)
	SIZE_CHECK=0
	;;
esac

#
# VERSION AND CHANGELOG
#
cd $ANDROID_BUILD_TOP
. build/envsetup.sh
VERSION_NUM_OLD=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
if [ "$1" != "-nocompile" ]; then
    VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    #GIT_LOG=$TOP/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
    # changelog - compare with old git hashes
    show_changelog.sh > /tmp/CHANGELOG
    echo "Updating ROM version..."
    if [ "$DEVBUILD" != "1" ]; then
	setromversion.sh
    fi
    VERSION_NUM_OLD=$VERSION_NUM
    VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    echo "Generating changelog..."
    # set new version and store new git hashes
    git_changelog.pl > /tmp/GIT_LOG
fi

VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)

GAPPS=$TOP/gapps_$OSARMOD_TYPE
GAPPS_ALT=$TOP/gapps_$OSARMOD_OS
if [ "$DEVBUILD" = "1" ]; then
    N=1
    TARGET=$TOP/build/$OSARMOD_TYPE/osarmod-${OSARMOD_OS}-rom-$MODEL-$VERSION_NUM-dev$N-signed.zip
    while [ -e $TARGET ]; do
	let N++
	TARGET=$TOP/build/$OSARMOD_TYPE/osarmod-${OSARMOD_OS}-rom-$MODEL-$VERSION_NUM-dev$N-signed.zip
    done
    VERSION_NUM=$VERSION_NUM-dev$N
else
    TARGET=$TOP/build/$OSARMOD_TYPE/osarmod-${OSARMOD_OS}-rom-$MODEL-$VERSION_NUM-signed.zip
fi
VERSION=osarmod-$VERSION_NUM

# Set the window title
echo -ne "\033]0;[Building] $OSARMOD_TYPE (ROM Version $VERSION_NUM) ...\007"

#
# COMPILE
#
case $OSARMOD_OS in
    cm*)
	OTAFILE="cm-*.zip"
	CLEANCMD="mka clean"
	BUILDCMD="mka bacon"
	export CYANOGEN_RELEASE=1 
	;;
    ics-*)
	OTAFILE="full_*.zip"
	CLEANCMD="make clean"
	BUILDCMD="make -j9"
	;;
    *)
	echo "OSARMOD_OS $OSARMOD_OS not supported"
	exit
	;;
esac

if [ "$1" != "-nocompile" ]; then
    echo "Building Android..."
    if [ "$1" = "-clean" ]; then
	$CLEANCMD
    fi
    $BUILDCMD
    OTAZIP=$(ls -1 $OUT/$OTAFILE|tail -1)
else
    if [ "$2" = "-ota" ]; then
	OTAZIP=$3
	if [ ! -e $OTAZIP ]; then
	    echo "$OTAZIP not found"
	    exit 1
	fi
    else
	OTAZIP=$(ls -1 $OUT/$OTAFILE|tail -1)
    fi
fi
# END OF COMPILE

#
# REPACKING OTA PACKAGE
#
if [ ! -e "$OTAZIP" ]; then
    sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE FAILED" -m "$TARGET"
    echo $VERSION_NUM_OLD > $TOP/files/VERSION_ROM_$OSARMOD_TYPE
    exit 1
fi

echo "Unpacking $OTAZIP..."
REPACK=$OUT/repack.d
rm -rf $REPACK
mkdir -p $REPACK
cd $REPACK
unzip -q $OTAZIP

echo "Adding Google Apps..."
if [ -d $GAPPS ]; then
    find $GAPPS/system -type f | perl -ne "s|$GAPPS/||; print '  [+] '.\$_"
    cp -r $GAPPS/system $REPACK
else
    find $GAPPS_ALT/system -type f | perl -ne "s|$GAPPS_ALT/||; print '  [+] '.\$_"
    cp -r $GAPPS_ALT/system $REPACK
fi

echo "Removing not needed files..."
for f in $(cat $TOP/files/REMOVE_ROM_FILES_$OSARMOD_TYPE); do
    echo "  [-] $f"
    rm -rf $REPACK/$f
done

echo "Adding additional files..."
find $ROMROOT/common-$OSARMOD_OS/ -type f | perl -ne "s|$ROMROOT/common-$OSARMOD_OS/||; print '  [+] '.\$_"
cp -r $ROMROOT/common-$OSARMOD_OS/* $REPACK
find $ROMROOT/$MODEL-$OSARMOD_OS/ -type f | perl -ne "s|$ROMROOT/$MODEL-$OSARMOD_OS/||; print '  [+] '.\$_"
cp -r $ROMROOT/$MODEL-$OSARMOD_OS/* $REPACK

cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/updater-script >> $REPACK/META-INF/com/google/android/updater-script
if [ -x $ROMROOT/$MODEL-${OSARMOD_OS}.ext/run.sh ]; then
    REPACK=$REPACK $ROMROOT/$MODEL-${OSARMOD_OS}.ext/run.sh
fi

echo "Setting ROM version to: $VERSION"
FILTER="ro.osarmod|ro.config.ringtone|ro.config.notification_sound"
FILTER_EXT="__EMPTY__"
if [ -r $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop.filter ]; then
    FILTER_EXT=$(cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop.filter)
fi
BUILD_ID=$(get_build_var BUILD_ID)
cat $REPACK/system/build.prop | egrep -vi "$FILTER" | egrep -vi "$FILTER_EXT" | \
    sed -e "s/ro.cm.version=.*/ro.cm.version=$VERSION/" | \
    sed -e "s/ro.build.display.id=.*/ro.build.display.id=$BUILD_ID/" > $REPACK/system/build.prop.new
echo "" >> $REPACK/system/build.prop.new
echo "# OSARMOD" >> $REPACK/system/build.prop.new
echo "ro.osarmod.version=$VERSION_NUM" >> $REPACK/system/build.prop.new
echo "ro.osarmod.ostype=$OSARMOD_OS" >> $REPACK/system/build.prop.new
echo "ro.osarmod.device=$OSARMOD_DEVICE" >> $REPACK/system/build.prop.new
echo "ro.config.ringtone=OM1.ogg" >> $REPACK/system/build.prop.new
echo "ro.config.notification_sound=OM1.ogg" >> $REPACK/system/build.prop.new
if [ -r $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop ]; then
    cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop >> $REPACK/system/build.prop.new
fi
mv $REPACK/system/build.prop.new $REPACK/system/build.prop

if [ $SIZE_CHECK = 1 ]; then
    echo -n "Checking size of system files... "
    s=$(du -sb $REPACK/system|awk '{print $1}')
    part=$(get_build_var BOARD_SYSTEMIMAGE_PARTITION_SIZE)
    if [ $s -lt $part ]; then
	echo "ok"
    else
	echo "failed ($s > $part)"
	sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE FAILED" -m "$TARGET"
	if [ "$1" != "-nocompile" ]; then
	    echo $VERSION_NUM_OLD > $TOP/files/VERSION_ROM_$OSARMOD_TYPE
	fi
	exit 1
    fi
fi

echo "Repacking..."
cd $REPACK
zip -q -r $OUT/tmposarrom.zip .

echo "Signing zip..."
rm -f $TARGET
signzip $OUT/tmposarrom.zip $TARGET

# cleanup
rm -rf $OUT/tmposarrom.zip $REPACK
if [ "$DEVBUILD" != "1" ]; then
    rm -f $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
    touch $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW

    # update build dir 
    cp $TOP/files/VERSION_ROM_$OSARMOD_TYPE $TOP/build/$OSARMOD_TYPE/version
    rm -f $TOP/build/$OSARMOD_TYPE/latest
    ln -s $TARGET $TOP/build/$OSARMOD_TYPE/latest
    # update dev files
    echo $VERSION_NUM > $TOP/build/$OSARMOD_TYPE/version_dev
    rm -f $TOP/build/$OSARMOD_TYPE/latest_dev
    ln -s $TARGET $TOP/build/$OSARMOD_TYPE/latest_dev
else
    # update build dir 
    echo $VERSION_NUM > $TOP/build/$OSARMOD_TYPE/version_dev
    rm -f $TOP/build/$OSARMOD_TYPE/latest_dev
    ln -s $TARGET $TOP/build/$OSARMOD_TYPE/latest_dev
fi
if [ -e /tmp/CHANGELOG ]; then
    mv /tmp/CHANGELOG $TOP/build/$OSARMOD_TYPE/CHANGELOG_${OSARMOD_TYPE}_$VERSION_NUM
fi
if [ -e /tmp/GIT_LOG ]; then
    mv /tmp/GIT_LOG $TOP/logs/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
fi
if [ -e /tmp/GIT_KLOG ]; then
    mv /tmp/GIT_KLOG $TOP/logs/GIT_KLOG_${OSARMOD_TYPE}_$VERSION_NUM
fi

echo "ROM finished: $TARGET"

sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE finished" -m "$TARGET"

# END OF REPACKING
