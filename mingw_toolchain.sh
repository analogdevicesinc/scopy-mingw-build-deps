#!/usr/bin/bash.exe

#TODO: make each dep install it's own deps
set -x
if [ "$CI_SCRIPT" == "ON" ]
	then
	set -ex
fi

if [ $# -ne 1 ];
	then
		ARG1=x86_64
	else
		ARG1=$1
fi
export ARCH=$ARG1

if [ "$ARCH" == "x86_64" ]
	then
		export MINGW_VERSION=mingw64
		export ARCH_BIT=64
	else
		export MINGW_VERSION=mingw32
		export ARCH_BIT=32
fi

export WORKFOLDER=${PWD}
USE_STAGING=$2
STAGING_PREFIX=$3

if [ ! -z "$USE_STAGING" ] && [ "$USE_STAGING" == "ON" ]
	then
		echo -- USING STAGING
		export USE_STAGING="ON"
		if [ -z "$STAGING_PREFIX" ]
			then
				STAGING_PREFIX="staging"
				export STAGING_ENV=$WORKFOLDER/staging_$ARCH
			else
				echo -- STAGING_PREFIX:$STAGING_PREFIX
				export STAGING_ENV=${STAGING_PREFIX}_${ARCH}
		fi
		export STAGING=${STAGING_PREFIX}_${ARCH}
		export STAGING_DIR=${WORKFOLDER}/${STAGING}/${MINGW_VERSION}
		export PACMAN="pacman -r $STAGING_ENV --noconfirm --needed"
	else
		echo -- NO STAGING
		export USE_STAGING=OFF
		export STAGING_DIR=/${MINGW_VERSION}
		export STAGING_ENV=""
		export PACMAN="pacman --noconfirm --needed"
fi

export PATH="/bin:$STAGING_DIR/bin:$WORKFOLDER/cv2pdb:/c/Program Files (x86)/Inno Setup 6:/c/innosetup/:/bin:/usr/bin:${STAGING_DIR}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32:/c/Program\ Files/Appveyor/BuildAgent:$PATH"
export QMAKE=${STAGING_DIR}/bin/qmake
export PKG_CONFIG_PATH=$STAGING_DIR/lib/pkgconfig
export CC=${STAGING_DIR}/bin/${ARCH}-w64-mingw32-gcc.exe
export CXX=${STAGING_DIR}/bin/${ARCH}-w64-mingw32-g++.exe
export JOBS="-j9"
export MAKE_BIN=$STAGING_ENV/usr/bin/make.exe
export MAKE_CMD="$MAKE_BIN $JOBS"
export CMAKE_GENERATOR="Unix Makefiles"
export CMAKE_OPTS=( \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_C_COMPILER:FILEPATH=${CC} \
	-DCMAKE_CXX_COMPILER:FILEPATH=${CXX} \
	-DCMAKE_MAKE_PROGRAM:FILEPATH=${MAKE_BIN}\
	-DPKG_CONFIG_EXECUTABLE=${STAGING_DIR}/bin/pkg-config.exe \
	-DCMAKE_MODULE_PATH=$STAGING_DIR \
	-DCMAKE_PREFIX_PATH=$STAGING_DIR/lib/cmake \
	-DCMAKE_STAGING_PREFIX=$STAGING_DIR \
	-DCMAKE_INSTALL_PREFIX=$STAGING_DIR \
)
export CMAKE="${STAGING_DIR}/bin/cmake ${CMAKE_OPTS[@]} "

export AUTOCONF_OPTS="--prefix=$STAGING_DIR \
	--host=${ARCH}-w64-mingw32 \
	--enable-shared \
	--disable-static"

if [ ${ARCH} == "i686" ]
	then
		export RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=$WORKFOLDER/windres/windres.exe"
	else
		export RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/mingw64/bin/windres.exe"
fi

BUILD_STATUS_FILE=/tmp/scopy-mingw-build-status
touch $BUILD_STATUS_FILE

echo -- MAKE_BIN:$MAKE_BIN
echo -- STAGING_DIR:$STAGING_DIR
echo -- STAGING_ENV:$STAGING_ENV
echo -- MINGW_VERSION:$MINGW_VERSION
echo -- TARGET ARCH:$ARCH
echo -- PATH:$PATH
echo -- USING CMAKE COMMAND
echo $CMAKE
echo
