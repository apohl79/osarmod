#!/bin/bash

export PATH=$PATH:$HOME/android/scripts

. $HOME/android/scripts/git.functions

if [ -z $OSARMOD_INIT ]; then
    echo "Target device selection:"
    echo ""
    echo "Android 4.1:"
    echo "  [1] Xoom (US WiFi)"
    echo ""
    echo "Android 4.2:"
    echo "  [2] Nexus 4"
    echo "  [3] Xoom (US WiFi)"
    echo ""
    echo -n "Choose target [none]: "
    read N
else
    N=$OSARMOD_INIT
fi

case $N in 
    1)
	target=wingray
	init=breakfast
	system=android/system_jellybean
	device=wingray
	device_common=moto/common
	os=cm10
	;;
    2)
	target=mako
	init=breakfast
	system=android/system_jb
	device=mako
	device_common=
	os=4.2
	;;
    3)
	target=wingray
	init=breakfast
	system=android/system_jb
	device=wingray
	device_common=moto/common
	os=4.2
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
    ./prebuilts/misc/linux-x86/ccache/ccache -M 100G
    export USE_CCACHE=1
    export OSARMOD_TYPE=${device}-${os}
    export OSARMOD_DEVICE=${device}
    export OSARMOD_DEVICE_COMMON=${device_common}
    export OSARMOD_OS=${os}
fi

function omsettitle() {
    if [ -n "$STY" ] ; then # We are in a screen session
	printf "\033k%s\033\\" "$@"
    else
	printf "\033]0;%s\007" "$@"
    fi
}

export OSARMOD_TITLE="${OSARMOD_TYPE}"
omsettitle "$OSARMOD_TITLE"

export PROMPT_COMMAND="echo -ne \"\033]0;[${OSARMOD_TYPE}] \$PWD\007\""
export PS1='\[\033[01;32m\]\u@\h (${OSARMOD_TYPE})\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

alias goto_system="cd $HOME/$system"
alias goto_romroot="cd $HOME/android/osarmod/romroot/${OSARMOD_TYPE}"
alias goto_osarmod="cd $HOME/android/osarmod"
alias goto_git="cd $HOME/android/git"
alias goto_build="cd $HOME/android/build/${OSARMOD_TYPE}"
alias goto_kernel="cd $HOME/android/kernel/osarmod-cm-kernel"
alias sc="show_changelog.sh -nodevs | less"
alias sc_all="show_changelog.sh -nodevs -all | less"
alias rs8="repo sync -j8"
alias devbuild="DEVBUILD=1 buildall.sh"
alias releasebuild="buildall.sh"
alias make_kernel='CROSS_COMPILE=$ARM_EABI_TOOLCHAIN/arm-eabi- ARCH=arm SUBARCH=arm make -j8'

alias edit_changelog="emacs $HOME/android/osarmod/CHANGELOG_${OSARMOD_TYPE}_NEW"
alias edit_romversion="emacs $HOME/android/osarmod/files/VERSION_ROM_${OSARMOD_TYPE}"
alias edit_remove_rom_files="emacs $HOME/android/osarmod/files/REMOVE_ROM_FILES_${OSARMOD_TYPE}"
alias edit_remove_gapps_files="emacs $HOME/android/osarmod/files/REMOVE_GAPPS_FILES_${OSARMOD_TYPE}"
