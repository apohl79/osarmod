#!/bin/bash

MAILTO=ap@diepohls.com
TOP=$HOME/android/osarmod
ROMROOT=$TOP/romroot

function main() {
    # trap ctrl-c and call ctrl_c()
    trap ctrl_c INT
	
    init_rom $*
    compile $*
    unpack_ota
    add_gapps_files
    remove_files
    add_additional_files
    update_build_prop
    size_check
    create_packages
    cleanup

    echo ""
    ls -sh $TARGET
    ls -sh $TARGET_INC
    echo ""
    echo "ROM finished."
    
    sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE finished" -m "$TARGET"
	
    finish
}

function ctrl_c() {
    finish
}

function finish() {
    omsettitle "$OSARMOD_TITLE"
    exit
}

function omsettitle() {
    if [ -n "$STY" ] ; then # We are in a screen session
	printf "\033k%s\033\\" "$@"
    else
	printf "\033]0;%s\007" "$@"
    fi
}

# Version and changelog
function init_rom() {
    MODEL=$OSARMOD_DEVICE
    
    cd $ANDROID_BUILD_TOP
    . build/envsetup.sh

    # Sync
    if [ "$1" == "-sync" ]; then
	shift
	omsettitle "[Building] ${OSARMOD_TYPE} (syncing source tree)..."
	repo sync -j8
    fi
    if [ "$1" != "-nocompile" ]; then
	NO_COMPILE=1
	shift
    fi    
    if [ "$1" = "-ota" ]; then
	OTA_BUILD=1
	OTA_PARAM_ZIP=$2
	shift
	shift
    fi

    SIZE_CHECK=0
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

    omsettitle "[Building] ${OSARMOD_TYPE} (generating version/changelog)..."
    VERSION_NUM_OLD=$(cat $TOP/files/VERSION_ROM_$OSARMOD_TYPE)
    if [ $NO_COMPILE = 1 ]; then
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
	TARGET=$TOP/build/$OSARMOD_TYPE/ionix-rom-$MODEL-$VERSION_NUM-dev$N-signed.zip
	while [ -e $TARGET ]; do
	    let N++
	    TARGET=$TOP/build/$OSARMOD_TYPE/ionix-rom-$MODEL-$VERSION_NUM-dev$N-signed.zip
	done
	TARGET_INC=$TOP/build/$OSARMOD_TYPE/incremental-dev.zip
	VERSION_NUM=$VERSION_NUM-dev$N
    else
	TARGET=$TOP/build/$OSARMOD_TYPE/ionix-rom-$MODEL-$VERSION_NUM-signed.zip
	TARGET_INC=$TOP/build/$OSARMOD_TYPE/incremental.zip
	TARGET_INC_DEV=$TOP/build/$OSARMOD_TYPE/incremental-dev.zip
    fi
    VERSION=ionix-$VERSION_NUM
    
    if [ ! -d $TOP/build/$OSARMOD_TYPE ]; then
	echo "Creating target direcory $TOP/build/${OSARMOD_TYPE}..."
	mkdir -p $TOP/build/$OSARMOD_TYPE
    fi
}

# Build Android
function compile() {
    omsettitle "[Building] $OSARMOD_TYPE (ROM Version $VERSION_NUM)..."
    
    OTAFILE="cm-*.zip"
    CLEANCMD="mka clean"
    BUILDCMD="mka bacon"
    export CYANOGEN_RELEASE=1 

    if [ $NO_COMPILE = 1 ]; then
	echo "Building Android..."
	if [ "$1" = "-clean" ]; then
	    $CLEANCMD
	fi
	$BUILDCMD
	OTAZIP=$(ls -1 $OUT/$OTAFILE|tail -1)
    else
	if [ $OTA_BUILD = 1 ]; then
	    OTAZIP=$OTA_PARAM_ZIP
	    if [ ! -e $OTAZIP ]; then
		echo "$OTAZIP not found"
		finish
	    fi
	else
	    OTAZIP=$(ls -1 $OUT/$OTAFILE|tail -1)
	fi
    fi
}

#
# REPACKING OTA PACKAGE
#
function unpack_ota() {
    if [ ! -e "$OTAZIP" ]; then
	sendemail -f root@dubidam.de -t $MAILTO -u "Build for $OSARMOD_TYPE FAILED" -m "$TARGET"
	echo $VERSION_NUM_OLD > $TOP/files/VERSION_ROM_$OSARMOD_TYPE
	finish
    fi
    echo "Unpacking $OTAZIP..."
    REPACK=$OUT/repack.d
    REPACK_INC=$OUT/repack_inc.d
    rm -rf $REPACK
    mkdir -p $REPACK
    cd $REPACK
    unzip -q $OTAZIP
}

function add_gapps_files() {
    echo "Adding Google Apps..."
    if [ -d $GAPPS ]; then
	find $GAPPS/system -type f | perl -ne "s|$GAPPS/||; print '  [+] '.\$_"
	cp -r $GAPPS/system $REPACK
    else
	find $GAPPS_ALT/system -type f | perl -ne "s|$GAPPS_ALT/||; print '  [+] '.\$_"
	cp -r $GAPPS_ALT/system $REPACK
    fi
}

function remove_files() {
    echo "Removing not needed files..."
    for f in $(cat $TOP/files/REMOVE_ROM_FILES_$OSARMOD_TYPE); do
	echo "  [-] $f"
	rm -rf $REPACK/$f
    done
}

function add_additional_files() {
    echo "Adding additional files..."
    find $ROMROOT/common-$OSARMOD_OS/ -type f | perl -ne "s|$ROMROOT/common-$OSARMOD_OS/||; print '  [+] '.\$_"
    cp -r $ROMROOT/common-$OSARMOD_OS/* $REPACK
    find $ROMROOT/$MODEL-$OSARMOD_OS/ -type f | perl -ne "s|$ROMROOT/$MODEL-$OSARMOD_OS/||; print '  [+] '.\$_"
    cp -r $ROMROOT/$MODEL-$OSARMOD_OS/* $REPACK
    
    cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/updater-script >> $REPACK/META-INF/com/google/android/updater-script
    if [ -x $ROMROOT/$MODEL-${OSARMOD_OS}.ext/run.sh ]; then
	REPACK=$REPACK $ROMROOT/$MODEL-${OSARMOD_OS}.ext/run.sh
    fi
}

function update_build_prop() {
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
    echo "ro.config.ringtone=OM3.ogg" >> $REPACK/system/build.prop.new
    echo "ro.config.notification_sound=OM1.ogg" >> $REPACK/system/build.prop.new
    if [ -r $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop ]; then
	cat $ROMROOT/$MODEL-${OSARMOD_OS}.ext/build.prop >> $REPACK/system/build.prop.new
    fi
    mv $REPACK/system/build.prop.new $REPACK/system/build.prop
}

function size_check() {
    echo "Calculating size of the system files..."
    du -sb $REPACK/system
    
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
	    finish
	fi
    fi
}

# Generate an incremental zip package
function generate_incremental_package() {
    old=$1
    new=$2
    out=$3
    rm -rf $out
    mkdir -p $out
    for f in $(rsync -rcn --out-format='%n' --exclude=META-INF $new/ $old/); do
	dir=$(dirname $f)
	if [ ! -d $out/$dir ]; then
	    mkdir -p $out/$dir
	fi
	if [ ! -d $new/$f ]; then
	    cp $new/$f $out/$f
	fi
    done
    cp $new/boot.img $out
    cp -r $new/META-INF $out
    cp $ROMROOT/$MODEL-${OSARMOD_OS}.ext/updater-script.inc $out/META-INF/com/google/android/updater-script
}

function create_packages() {
    echo "Creating full package..."
    cd $REPACK
    zip -q -r $OUT/tmposarrom.zip .

    echo "Signing zip..."
    rm -f $TARGET
    signzip $OUT/tmposarrom.zip $TARGET
    
    echo "Unpacking previous package..."
    rm -rf /tmp/prev
    if [ "$DEVBUILD" != "1" ]; then
	unzip -q $TOP/build/$OSARMOD_TYPE/latest -d /tmp/prev
    else
	unzip -q $TOP/build/$OSARMOD_TYPE/latest_dev -d /tmp/prev
    fi
    
    echo "Creating incremental package..."
    generate_incremental_package /tmp/prev $REPACK $REPACK_INC
    cd $REPACK_INC
    rm -f $OUT/tmposarrom.zip
    zip -q -r $OUT/tmposarrom.zip .
    
    echo "Signing zip..."
    rm -f $TARGET_INC
    signzip $OUT/tmposarrom.zip $TARGET_INC
}

function cleanup() {
    # cleanup
    rm -rf $OUT/tmposarrom.zip $REPACK $REPACK_INC /tmp/prev
    if [ "$DEVBUILD" != "1" ]; then
	rm -f $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
	touch $TOP/CHANGELOG_${OSARMOD_TYPE}_NEW
	
        # update build dir 
	mv $TOP/build/$OSARMOD_TYPE/version $TOP/build/$OSARMOD_TYPE/version_prev
	cp $TOP/files/VERSION_ROM_$OSARMOD_TYPE $TOP/build/$OSARMOD_TYPE/version
	mv $TOP/build/$OSARMOD_TYPE/latest $TOP/build/$OSARMOD_TYPE/previous
	ln -s $TARGET $TOP/build/$OSARMOD_TYPE/latest
        # update dev files
	cp $TOP/build/$OSARMOD_TYPE/version_prev $TOP/build/$OSARMOD_TYPE/version_dev_prev
	echo $VERSION_NUM > $TOP/build/$OSARMOD_TYPE/version_dev
	mv $TOP/build/$OSARMOD_TYPE/latest_dev $TOP/build/$OSARMOD_TYPE/previous_dev
	ln -s $TARGET $TOP/build/$OSARMOD_TYPE/latest_dev
	rm -f $TARGET_INC_DEV
	ln -s $TARGET_INC $TARGET_INC_DEV
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
}

main $*
