#!/bin/bash

MAILTO=apohl79@gmail.com
ROMROOT=$HOME/android/romroot
MODEL=$(echo -n $TARGET_PRODUCT|sed 's/cyanogen_//'|sed 's/full_//')

case $MODEL in
    galaxys*)
	TYPE=cm7
	OTAFILE="update-cm-*.zip"
	;;
    wingray)
	TYPE=ics-aosp
	OTAFILE="full_*.zip"
	;;
    *)
	echo "TARGET_PRODUCT $TARGET_PRODUCT not supported"
	exit
	;;
esac

if [ "$1" != "-nocompile" ]; then
    echo "Updating ROM version..."
    setromversion.sh
fi

VERSION_NUM=$(cat $HOME/android/VERSION_ROM_$TARGET_PRODUCT)
VERSION=osarmod-$TYPE-$VERSION_NUM
GAPPS=$HOME/android/gapps_$TYPE
TARGET=$HOME/android/build/osarmod-$TYPE-rom-$MODEL-$VERSION_NUM-signed.zip

#
# COMPILE
#
if [ "$1" != "-nocompile" ]; then
    echo "Building Android..."
    cd $ANDROID_BUILD_TOP
    . build/envsetup.sh
    if [ "$TYPE" = "cm7" ]; then
	export CYANOGEN_RELEASE=1 
	mka clean
	mka bacon
    else
	make clean
	make -j9 otapackage
    fi
fi
# END OF COMPILE

#
# REPACKING OTA PACKAGE
#
OTAZIP=$(echo $OUT/$OTAFILE)

echo "Unpacking $OTAZIP..."
REPACK=$OUT/repack.d
rm -rf $REPACK
mkdir -p $REPACK
cd $REPACK
unzip -q $OTAZIP

echo "Adding Google Apps..."
cp -r $GAPPS/system $REPACK

echo "Removing not needed files..."
for f in $(cat $HOME/android/REMOVE_ROM_FILES_$TARGET_PRODUCT); do
    echo "  [-] $f"
    rm -rf $REPACK/$f
done

echo "Adding additional files..."
cp -r $ROMROOT/common-$TYPE/* $REPACK
cp -r $ROMROOT/$MODEL-$TYPE/* $REPACK

echo "Setting ROM version to: $VERSION"
case $TYPE in
    cm7)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.modversion=.*\)/ro.modversion=$VERSION/" > $REPACK/system/build.prop.new
	;;
    ics-aosp)
	cat $REPACK/system/build.prop | sed -e "s/\(ro.build.display.id=.*\)/ro.build.display.id=$VERSION/" > $REPACK/system/build.prop.new
	;;
esac
mv $REPACK/system/build.prop.new $REPACK/system/build.prop

echo "Repacking..."
cd $REPACK
zip -q -r $OUT/tmposarrom.zip .

echo "Signing zip..."
rm -f $TARGET
signzip $OUT/tmposarrom.zip $TARGET

# cleanup
rm -rf $OUT/tmposarrom.zip $REPACK

echo "ROM finished: $TARGET"

sendemail -f root@dubidam.de -t $MAILTO -u "Build finished" -m "$TARGET"
 
# END OF REPACKING
