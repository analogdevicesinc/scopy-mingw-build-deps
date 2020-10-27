#!/bin/bash

ARCH="$1"
MINGW_VERSION="$2"

PACKAGES="libusb boost qt5 breakpad"
libusb_VER="1.0.21-2"
boost_VER="1.72.0-3"
qt5_VER="5.14.2-3"
breakpad_VER="git-r1680.70914b2d-1"

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32
mirrorlist=$( cat /etc/pacman.d/mirrorlist.msys | grep "Server = " | cut -d ' ' -f3 | /c/msys64/usr/bin/rev | cut -d '/' -f4- | /c/msys64/usr/bin/rev )
mkdir -p old_msys_deps_$MINGW_VERSION && cd old_msys_deps_$MINGW_VERSION

PAK_TYPE="mingw"
PAK_ARCH="any"

## TEMP FIX / HACK
CUR_PWD=$(pwd)
mkdir -p /temp
cd /temp
wget https://ci.appveyor.com/api/buildjobs/f5pekeileekr4ohg/artifacts/old-msys-build-deps-mingw64.tar.xz
wget https://ci.appveyor.com/api/buildjobs/csb4ln2pv39xpjbd/artifacts/old-msys-build-deps-mingw32.tar.xz
cd $CUR_PWD
cd ..
tar xvf /temp/old-msys-build-deps-$MINGW_VERSION.tar.xz 
pwd
echo $CUR_PWD
cd $CUR_PWD
ls
ls -la
# END HACK
rm -rf old-msys-build-deps-mingw64.tar.xz
rm -rf old-msys-build-deps-mingw32.tar.xz
echo deleted archives
cd .. 
tar cavf old-msys-build-deps-$MINGW_VERSION.tar.xz old_msys_deps_$MINGW_VERSION
cd $CUR_PWD
