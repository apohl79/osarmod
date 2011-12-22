#!/bin/bash

export PATH=$PATH:$HOME/android/scripts

echo "Target device selection:"
echo ""
echo "  [1] Galaxy S"
echo "  [2] Galaxy S II"
echo "  [3] Xoom (US WiFi)"
echo ""
echo -n "Choose target [none]: "
read N

case $N in 
    1)
	target=galaxysmtd
	init=breakfast
	system=android/system
	;;
    2)
	target=galaxys2
	init=breakfast
	system=android/system
	;;
    3)
	target=full_wingray-userdebug
	init=lunch
	system=android/system_aosp_ics
	;;
    *)
	target=none
	;;
esac

if [ "$target" = "none" ]; then
    cd android
    export TARGET_PRODUCT=none
else
    cd $system
    . build/envsetup.sh
    $init $target
    ./prebuilt/linux-x86/ccache/ccache -M 50G
fi

export PROMPT_COMMAND="echo -ne \"\033]0;[${TARGET_PRODUCT}] \$PWD\007\""
export PS1='\[\033[01;32m\]\u@\h (${TARGET_PRODUCT})\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
