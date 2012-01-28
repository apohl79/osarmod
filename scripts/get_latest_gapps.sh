#!/bin/bash

TYPE=$1
case $TYPE in
    gb)
	URL=http://cmw.22aaf3.com/gapps/
	PATTERN="gapps-gb-[0-9]+-signed.zip"
	;;
    ics)
	URL=http://download.clockworkmod.com/test/
	;;
    *)
	echo "$0 {gb|ics}"
	exit
	;;
esac

DIR=$HOME/android/osarmod

if [ -z "$2" ]; then 
    # get latest gapps package
    LATEST_GAPPS=$(curl -s $URL | perl -ne "if (/($PATTERN)/) {print \$1.\"\n\"}" | sort | tail -1)
    if [ -e $DIR/$LATEST_GAPPS ]; then
	echo "$LATEST_GAPPS is up to date."
	exit
    fi
    echo "Downloading $LATEST_GAPPS"  
    curl $URL$LATEST_GAPPS -o $DIR/$LATEST_GAPPS
else
    LATEST_GAPPS=$2
fi

echo "Unpacking to $DIR/gapps..."
rm -rf $DIR/gapps_$TYPE
unzip -o $DIR/$LATEST_GAPPS -d $DIR/gapps_$TYPE

echo "Removing unwanted apk's..."
for f in $(cat $DIR/REMOVE_GAPPS_FILES_$TYPE); do
    echo "  [-] $f"
    rm -f $DIR/gapps_$TYPE/system/app/$f   
done
