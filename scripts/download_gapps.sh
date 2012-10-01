#!/bin/bash
DIR=$HOME/android/osarmod
URL=$1
FILE=$(basename $URL)

cd $DIR

if [ -e $DIR/$FILE ]; then
    echo "$DIR/$FILE exists. Skipping download."
else
    wget $URL
fi


echo "Unpacking to $DIR/gapps_${OSARMOD_TYPE}..."
rm -rf $DIR/gapps_$OSARMOD_TYPE
unzip -o $DIR/$FILE -d $DIR/gapps_$OSARMOD_TYPE

echo "Removing unwanted apk's..."
for f in $(cat $DIR/files/REMOVE_GAPPS_FILES_$OSARMOD_TYPE); do
    echo "  [-] $f"
    rm -rf $DIR/gapps_$OSARMOD_TYPE/$f   
done
