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
for PAK in $PACKAGES
do
	PAK_VER="$PAK"_VER
	if [[ $PAK_TYPE == "mingw" ]]; then
		PAK_NAME=mingw-w64-$ARCH-$PAK-${!PAK_VER}-$PAK_ARCH
	else
		PAK_NAME=$PAK-${!PAK_VER}-$PAK_ARCH
	fi

	for MSYS_MIRROR in $mirrorlist
	do
		EXT="xz"
		URL=$MSYS_MIRROR/$PAK_TYPE/$ARCH/$PAK_NAME.pkg.tar.$EXT
		if curl --output /dev/null --silent --head --fail "$URL"; then
			echo "FOUND: " $PAK-${!PAK_VER} " on " $MSYS_MIRROR
			wget "$URL"
			break
		else
			EXT="zst"
			URL=$MSYS_MIRROR/$PAK_TYPE/$ARCH/$PAK_NAME.pkg.tar.$EXT
			if curl --output /dev/null --silent --head --fail "$URL"; then
				echo "FOUND: " $PAK-${!PAK_VER} " on " $MSYS_MIRROR
				wget "$URL"
				break
			else
				echo "NOT FOUND: " $PAK-${!PAK_VER} " on " $MSYS_MIRROR " Trying other mirrors."
			fi
		fi
	done
done


#TEMP TODO:remove
#These are temporary until some MSYS2 signature issues get fixed
TEMP_URLS="http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz \
http://repo.msys2.org/msys/x86_64/msys2-keyring-r21.b39fb11-1-any.pkg.tar.xz.sig \
http://repo.msys2.org/msys/x86_64/pacman-5.2.2-1-x86_64.pkg.tar.xz"

for URL in $TEMP_URLS
do
	for MSYS_MIRROR in $mirrorlist
	do
		if curl --output /dev/null --silent --head --fail "$URL"; then
			echo "FOUND: " $URL " on " $MSYS_MIRROR
			wget "$URL"
			break
		else
			echo "NOT FOUND: " $PAK-${!PAK_VER} " on " $MSYS_MIRROR " Trying other mirrors."
		fi
	done
done

cd ..
tar cavf old-msys-build-deps-$MINGW_VERSION.tar.xz old_msys_deps_$MINGW_VERSION
