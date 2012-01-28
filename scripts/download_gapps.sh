#!/bin/bash
DIR=$HOME/android/osarmod
URL=$1
FILE=$(basename $URL)

if [ -e $DIR/$FILE ]; then
    echo "$DIR/$FILE exists. Terminating."
    exit
fi

cd $DIR
wget $URL

echo "Unpacking to $DIR/gapps_${OSARMOD_TYPE}..."
rm -rf $DIR/gapps_$OSARMOD_TYPE
unzip -o $DIR/$FILE -d $DIR/gapps_$OSARMOD_TYPE

echo "Removing unwanted apk's..."
for f in $(cat $DIR/REMOVE_GAPPS_FILES_$OSARMOD_TYPE); do
    echo "  [-] $f"
    rm -f $DIR/gapps_$OSARMOD_TYPE/system/app/$f   
done
