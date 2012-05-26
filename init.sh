#!/bin/bash

export PATH=$PATH:$HOME/android/scripts

if [ -z $OSARMOD_INIT ]; then
    echo "Target device selection:"
    echo ""
    echo "  [1] Galaxy S - CM9"
    echo "  [2] Xoom (US WiFi) - CM9"
    echo ""
    echo -n "Choose target [none]: "
    read N
else
    N=$OSARMOD_INIT
fi

case $N in 
    1)
	target=galaxysmtd
	init=breakfast
	system=android/system_ics
	device=galaxysmtd
	device_common=aries-common
	os=cm9
	;;
    2)
	target=wingray
	init=breakfast
	system=android/system_ics
	device=wingray
	device_common=moto/common
	os=cm9
	;;
    *)
	target=none
	;;
esac

if [ "$target" = "none" ]; then
    cd android
    export TARGET_PRODUCT=none
else
    cd $HOME/$system
    . build/envsetup.sh
    $init $target
    ./prebuilt/linux-x86/ccache/ccache -M 100G
    export USE_CCACHE=1
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
alias goto_kernel="cd $HOME/android/kernel/osarmod-cm-kernel"
alias edit_changelog="emacs $HOME/android/osarmod/CHANGELOG_${OSARMOD_TYPE}_NEW"
alias edit_romversion="emacs $HOME/android/osarmod/VERSION_ROM_${OSARMOD_TYPE}"
alias sc="show_changelog.sh | less"
alias devbuild="DEVBUILD=1 buildall.sh"
alias releasebuild="buildall.sh"
