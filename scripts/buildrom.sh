#!/bin/bash

MAILTO=ap@diepohls.com
TOP=$HOME/android/osarmod
ROMROOT=$TOP/romroot
#MODEL=$(echo -n $TARGET_PRODUCT|sed 's/cyanogen_//'|sed 's/full_//')
MODEL=$OSARMOD_DEVICE

case $OSARMOD_OS in
    cm*)
	OTAFILE="update-cm-*.zip"
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
    VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    #GIT_LOG=$TOP/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
    # changelog - compare with old git hashes
    cd $ANDROID_BUILD_TOP
    show_changelog.sh > /tmp/CHANGELOG
    echo "Updating ROM version..."
    setromversion.sh
    VERSION_NUM_OLD=$VERSION_NUM
    VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    mv /tmp/CHANGELOG $TOP/CHANGELOG_${OSARMOD_TYPE}_$VERSION_NUM
    echo "Generating changelog..."
    # set new version and store new git hashes
    git_changelog.pl > $TOP/files/GIT_LOG_${OSARMOD_TYPE}_$VERSION_NUM
fi

VERSION_NUM=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
VERSION=osarmod-${OSARMOD_OS}-$VERSION_NUM
GAPPS=$TOP/gapps_$OSARMOD_TYPE
GAPPS_ALT=$TOP/gapps_$OSARMOD_OS
TARGET=$TOP/build/$OSARMOD_TYPE/osarmod-${OSARMOD_OS}-rom-$MODEL-$VERSION_NUM-signed.zip

#
# COMPILE
#
if [ "$1" != "-nocompile" ]; then
    echo "Building Android..."
    cd $ANDROID_BUILD_TOP
    . build/envsetup.sh
    if [ "$1" = "-clean" ]; then
	$CLEANCMD
    fi
    $BUILDCMD
    OTAZIP=$(echo $OUT/$OTAFILE)
else
    if [ "$2" = "-ota" ]; then
	OTAZIP=$3
	if [ ! -e $OTAZIP ]; then
	    echo "$OTAZIP not found"
	    exit 1
	fi
    else
	OTAZIP=$(echo $OUT/$OTAFILE)
    fi
fi
# END OF COMPILE

#
# REPACKING OTA PACKAGE
#
if [ ! -e $OTAZIP ]; then
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
    cp -r $GAPPS/system $REPACK
else
    cp -r $GAPPS_ALT/system $REPACK
fi

echo "Removing not needed files..."
for f in $(cat $TOP/files/REMOVE_ROM_FILES_$OSARMOD_TYPE); do
    echo "  [-] $f"
    rm -rf $REPACK/$f
done

echo "Adding additional files..."
cp -r $ROMROOT/common-$OSARMOD_OS/* $REPACK
cp -r $ROMROOT/$MODEL-$OSARMOD_OS/* $REPACK

echo "Setting ROM version to: $VERSION"
case $OSARMOD_OS in
    cm7)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.modversion=.*\)/ro.modversion=$VERSION/" > $REPACK/system/build.prop.new
	mv $REPACK/system/build.prop.new $REPACK/system/build.prop
	;;
    cm9)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.cm.version=.*\)/ro.cm.version=$VERSION/" > $REPACK/system/build.prop.new
	mv $REPACK/system/build.prop.new $REPACK/system/build.prop
	;;
    *)
	BUILD_ID=$(cat $REPACK/system/build.prop | grep build.id | sed 's/ro.build.id=//')
	cat $REPACK/system/build.prop | sed -e "s/\(ro.build.display.id=.*\)/ro.build.display.id=$VERSION ($BUILD_ID)/" > $REPACK/system/build.prop.new
	mv $REPACK/system/build.prop.new $REPACK/system/build.prop
	;;
esac

echo "Repacking..."
cd $REPACK
zip -q -r $OUT/tmposarrom.zip .

echo "Signing zip..."
rm -f $TARGET
signzip $OUT/tmposarrom.zip $TARGET

# cleanup
rm -rf $OUT/tmposarrom.zip $REPACK
rm -f $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
touch $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW

# copy changelog
mv $TOP/CHANGELOG_${OSARMOD_TYPE}_$VERSION_NUM $TOP/build/$OSARMOD_TYPE

echo "ROM finished: $TARGET"

sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE finished" -m "$TARGET"

# END OF REPACKING
