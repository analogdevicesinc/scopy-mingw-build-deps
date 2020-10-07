#!/usr/bin/bash.exe
PACMAN_INIT="$1"

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32
mirrorlist=$( cat /etc/pacman.d/mirrorlist.msys | grep "Server = " | cut -d ' ' -f3 | /c/msys64/usr/bin/rev | cut -d '/' -f4- | /c/msys64/usr/bin/rev )
for m in $mirrorlist
do
	response=$(curl -Is $m | grep HTTP | cut -d ' ' -f2)
	if [[ $response != "" ]]
	then
	    MSYS_MIRROR=$m
		break
	fi
done
export MSYS_MIRROR=$MSYS_MIRROR

if [ "$PACMAN_INIT" == "true" ] ; then
		pacman --noconfirm -U $MSYS_MIRROR/msys/x86_64/pacman-5.2.2-1-x86_64.pkg.tar.xz
		curl -O $MSYS_MIRROR/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
		curl -O $MSYS_MIRROR/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig
		pacman-key --verify msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz{.sig,}
		pacman-key --populate
		pacman --noconfirm -U msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz
fi
