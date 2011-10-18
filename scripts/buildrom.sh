#!/bin/bash

GAPPS=$HOME/android/gapps
AAPPS=$HOME/android/aapps
MODEL=`echo -n $TARGET_PRODUCT|sed 's/cyanogen_//'`
DATE=`date +%Y%m%d`
TARGET=$HOME/android/build/cm-osar-$MODEL-$DATE-signed.zip
VERSION=osar-$DATE

echo "Building CyanogenMod..."
cd $ANDROID_BUILD_TOP
. build/envsetup.sh
export CYANOGEN_RELEASE=1 
mka bacon

CMZIP=`echo $OUT/update-cm-*.zip`

echo "Unpacking $CMZIP..."

REPACK=$OUT/repack.d
rm -rf $REPACK
mkdir -p $REPACK
cd $REPACK
unzip -q $CMZIP

echo "Adding Google Apps..."

cp $GAPPS/system/app/FOTAKill.apk $REPACK/system/app
cp $GAPPS/system/app/GenieWidget.apk $REPACK/system/app
cp $GAPPS/system/app/GoogleBackupTransport.apk $REPACK/system/app
cp $GAPPS/system/app/GoogleCalendarSyncAdapter.apk $REPACK/system/app
cp $GAPPS/system/app/GoogleContactsSyncAdapter.apk $REPACK/system/app
cp $GAPPS/system/app/GooglePartnerSetup.apk $REPACK/system/app
cp $GAPPS/system/app/GoogleQuickSearchBox.apk $REPACK/system/app
cp $GAPPS/system/app/GoogleServicesFramework.apk $REPACK/system/app
cp $GAPPS/system/app/MarketUpdater.apk $REPACK/system/app
cp $GAPPS/system/app/MediaUploader.apk $REPACK/system/app
cp $GAPPS/system/app/NetworkLocation.apk $REPACK/system/app
cp $GAPPS/system/app/OneTimeInitializer.apk $REPACK/system/app
cp $GAPPS/system/app/SetupWizard.apk $REPACK/system/app
cp $GAPPS/system/app/Talk.apk $REPACK/system/app
cp $GAPPS/system/app/Vending.apk $REPACK/system/app
cp -r $GAPPS/system/etc $REPACK/system
cp -r $GAPPS/system/framework $REPACK/system
cp -r $GAPPS/system/lib $REPACK/system

echo "Removing not needed Apps..."

rm -f $REPACK/system/app/AndroidTerm.apk
rm -f $REPACK/system/app/Androidian.apk
rm -f $REPACK/system/app/CMWallpapers.apk
rm -f $REPACK/system/app/Cyanbread.apk
rm -f $REPACK/system/app/Development.apk
rm -f $REPACK/system/app/Email.apk
rm -f $REPACK/system/app/FM.apk
rm -f $REPACK/system/app/GenieWidget.apk
rm -f $REPACK/system/app/LiveWallpapers.apk
rm -f $REPACK/system/app/LiveWallpapersPicker.apk
rm -f $REPACK/system/app/MagicSmokeWallpapers.apk
rm -f $REPACK/system/app/Pacman.apk
rm -f $REPACK/system/app/Protips.apk
rm -f $REPACK/system/app/Talk.apk

echo "Adding additional Apps..."

cp -r $AAPPS/common/* $REPACK
cp -r $AAPPS/$MODEL/* $REPACK

echo "Setting ROM version to: $VERSION"
cat $REPACK/system/build.prop | sed -e "s/\(ro.modversion=.*\)/\\1-$VERSION/" > $REPACK/system/build.prop.new
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
