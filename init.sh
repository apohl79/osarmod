#!/bin/bash

export PATH=$PATH:$HOME/android/scripts

echo "Target device selection:"
echo ""
echo "  [1] Galaxy S - CM7"
echo "  [2] Galaxy S II - CM7"
echo "  [3] Xoom (US WiFi) - ICS/AOSP"
echo "  [4] Xoom (US WiFi) - CM9"
#echo "  [5] Xoom (US WiFi) - ICS/EOS"
echo ""
echo -n "Choose target [none]: "
read N

case $N in 
    1)
	target=galaxysmtd
	init=breakfast
	system=android/system_gb
	device=galaxysmtd
	device_common=aries-common
	os=cm7
	;;
    2)
	target=galaxys2
	init=breakfast
	system=android/system_gb
	device=galaxys2
	device_common=c1-common
	os=cm7
	;;
    3)
	target=full_wingray-userdebug
	init=lunch
	system=android/system_aosp_ics
	device=wingray
	device_common=moto/common
	os=ics-aosp
	;;
    4)
	target=wingray
	init=breakfast
	system=android/system_ics
	device=wingray
	device_common=moto/common
	os=cm9
	;;
    5)
	target=full_wingray-userdebug
	init=lunch
	system=android/system_eos_ics
	device=wingray
	device_common=moto/common
	os=ics-eos
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
    ./prebuilt/linux-x86/ccache/ccache -M 100G
    export OSARMOD_TYPE=${device}-${os}
    export OSARMOD_DEVICE=${device}
    export OSARMOD_DEVICE_COMMON=${device_common}
    export OSARMOD_OS=${os}
fi

export PROMPT_COMMAND="echo -ne \"\033]0;[${OSARMOD_TYPE}] \$PWD\007\""
export PS1='\[\033[01;32m\]\u@\h (${OSARMOD_TYPE})\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

alias goto_system="cd $HOME/$system"
alias goto_romroot="cd $HOME/android/osarmod/romroot/$OSARMOD_TYPE"
alias goto_osarmod="cd $HOME/android/osarmod"
alias goto_build="cd $HOME/android/build"
alias edit_changelog="emacs $HOME/android/osarmod/CHANGELOG_${OSARMOD_TYPE}_NEW"
alias edit_romversion="emacs $HOME/android/osarmod/VERSION_ROM_${OSARMOD_TYPE}"
alias rs="repo sync -j16"
alias sc="show_changelog.sh | less"
