#!/bin/bash

URL=http://cmw.22aaf3.com/gapps/
DIR=$HOME/android

# get latest gapps package
LATEST_GAPPS=$(curl -s $URL | perl -ne 'if (/(gapps-gb-[0-9]+-signed.zip)/) {print $1."\n"}' | sort | tail -1)
LATEST_GAPPS_MD5=$(echo $LATEST_GAPPS | sed s/zip$/md5/)

echo $LATEST_GAPPS  
curl $URL$LATEST_GAPPS -o $DIR/$LATEST_GAPPS
echo $LATEST_GAPPS_MD5
curl $URL$LATEST_GAPPS_MD5 -o $DIR/$LATEST_GAPPS_MD5

# md5sum -c doesn't work because the md5 sumfiles are broken
MD5=$(cat $DIR/$LATEST_GAPPS_MD5 | grep gapps-gb | awk '{print $1}')
MD5_check=$(md5sum $DIR/$LATEST_GAPPS | awk '{print $1}')
if [ "$MD5" = "$MD5_check" ]; then
    echo "Unpacking to $DIR/gapps..."
    rm -rf $DIR/gapps
    unzip $DIR/$LATEST_GAPPS -d $DIR/gapps
else
    echo "ERROR: MD5 mismatch: $MD5 != $MD5_check"
fi
