#!/bin/bash

MAILTO=ap@diepohls.com
TOP=$HOME/android/osarmod
ROMROOT=$TOP/romroot
MODEL=$OSARMOD_DEVICE

#
# PREPARING THE KERNEL
#
case $OSARMOD_DEVICE in
    galaxysmtd)
	KERNEL_PATH=kernel/samsung/aries
	KERNEL_BRANCH=ics
	;;
    wingray)
	KERNEL_PATH=
	KERNEL_BRANCH=
	;;
esac

if [ -n "$KERNEL_PATH" ]; then
    cd $KERNEL_PATH
    #git co $KERNEL_BRANCH
    git_changelog.pl > /tmp/GIT_KLOG
    cd -
fi

#
# VERSION AND CHANGELOG
#
if [ "$1" != "-nocompile" ]; then
    VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    #GIT_LOG=$TOP/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
    # changelog - compare with old git hashes
    cd $ANDROID_BUILD_TOP
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
VERSION=osarmod-${OSARMOD_OS}-$VERSION_NUM

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
    cd $ANDROID_BUILD_TOP
    . build/envsetup.sh
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
    find $GAPPS/system -type f
    cp -r $GAPPS/system $REPACK
else
    find $GAPPS_ALT/system -type f
    cp -r $GAPPS_ALT/system $REPACK
fi

echo "Removing not needed files..."
for f in $(cat $TOP/files/REMOVE_ROM_FILES_$OSARMOD_TYPE); do
    echo "  [-] $f"
    rm -rf $REPACK/$f
done

echo "Adding additional files..."
find $ROMROOT/common-$OSARMOD_OS/ -type f
cp -r $ROMROOT/common-$OSARMOD_OS/* $REPACK
find $ROMROOT/$MODEL-$OSARMOD_OS/ -type f
cp -r $ROMROOT/$MODEL-$OSARMOD_OS/* $REPACK

cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/updater-script >> $REPACK/META-INF/com/google/android/updater-script

echo "Setting ROM version to: $VERSION"
case $OSARMOD_OS in
    cm7)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.modversion=.*\)/ro.modversion=$VERSION/" > $REPACK/system/build.prop.new
	;;
    cm9|cm10)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.cm.version=.*\)/ro.cm.version=$VERSION/" > $REPACK/system/build.prop.new
	;;
    *)
	BUILD_ID=$(cat $REPACK/system/build.prop | grep build.id | sed 's/ro.build.id=//')
	cat $REPACK/system/build.prop | sed -e "s/\(ro.build.display.id=.*\)/ro.build.display.id=$VERSION ($BUILD_ID)/" > $REPACK/system/build.prop.new
	;;
esac
echo "" >> $REPACK/system/build.prop.new
echo "# OSARMOD" >> $REPACK/system/build.prop.new
echo "ro.osarmod.version=$VERSION_NUM" >> $REPACK/system/build.prop.new
echo "ro.osarmod.ostype=$OSARMOD_OS" >> $REPACK/system/build.prop.new
echo "ro.osarmod.device=$OSARMOD_DEVICE" >> $REPACK/system/build.prop.new
mv $REPACK/system/build.prop.new $REPACK/system/build.prop

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
mv /tmp/CHANGELOG $TOP/build/$OSARMOD_TYPE/CHANGELOG_${OSARMOD_TYPE}_$VERSION_NUM
mv /tmp/GIT_LOG $TOP/files/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
#mv /tmp/GIT_KLOG $TOP/files/GIT_KLOG_${OSARMOD_TYPE}_$VERSION_NUM

echo "ROM finished: $TARGET"

sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE finished" -m "$TARGET"

# END OF REPACKING
