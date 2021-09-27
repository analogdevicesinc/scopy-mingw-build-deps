#!/usr/bin/bash.exe
source build_system_setup.sh

BUILD_STATUS_FILE=/tmp/scopy-mingw-build-status
touch $BUILD_STATUS_FILE

#TODO: make each dep install it's own deps
# Exit immediately if an error occurs
#set -e
#set -x 

if [ $# -ne 1 ]; then
	ARG1=x86_64
else
	ARG1=$1
fi
export ARCH=$ARG1
if [ $ARCH == "x86_64" ]
then
	export MINGW_VERSION=mingw64
	export ARCH_BIT=64
else
	export MINGW_VERSION=mingw32
	export ARCH_BIT=32
fi

echo $STAGING_PREFIX is the staging prefix
export STAGING=${STAGING_PREFIX}_${ARCH}
export JOBS="-j9"

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32:/c/Program\ Files/Appveyor/BuildAgent

export WORKDIR=${PWD}

if [ -z "$STAGING_PREFIX" ]
	then 
		export STAGING_DIR=$WORKDIR/staging_$ARCH/$MINGW_VERSION
		export STAGING_ENV=$WORKDIR/staging_$ARCH
	else
		export STAGING_DIR=$STAGING/$MINGW_VERSION
		export STAGING_ENV=$STAGING
fi

export CC=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-gcc.exe
export CXX=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-g++.exe
export JOBS="-j 9"
export MAKE_BIN=/${MINGW_VERSION}/bin/mingw32-make.exe 
export MAKE_CMD="$MAKE_BIN $JOBS"
export CMAKE_GENERATOR="Unix Makefiles"
export CMAKE_OPTS=( \
	-DCMAKE_C_COMPILER:FILEPATH=${CC} \
	-DCMAKE_CXX_COMPILER:FILEPATH=${CXX} \
	-DCMAKE_MAKE_PROGRAM:FILEPATH=${MAKE_BIN}\
	-DPKG_CONFIG_EXECUTABLE=/$MINGW_VERSION/bin/pkg-config.exe \
	-DCMAKE_MODULE_PATH=$STAGING_DIR \
	-DCMAKE_PREFIX_PATH=$STAGING_DIR/lib/cmake \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_STAGING_PREFIX=$STAGING_DIR \
	-DCMAKE_INSTALL_PREFIX=$STAGING_DIR \
)
export QMAKE="$STAGING_DIR/bin/qmake"
export CMAKE="/$MINGW_VERSION/bin/cmake ${CMAKE_OPTS[@]} "
export PACMAN="pacman -r $STAGING_ENV --noconfirm --needed"
export PKG_CONFIG_PATH=$STAGING_DIR/lib/pkgconfig

export AUTOCONF_OPTS="--prefix=$STAGING_DIR \
	--host=${ARCH}-w64-mingw32 \
	--enable-shared \
	--disable-static"

if [ ${ARCH} == "i686" ]
then
	export RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=$WORKDIR/windres/windres.exe"
else
	export RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/mingw64/bin/windres.exe"
fi

echo -- $STAGING_DIR is the staging dir
echo -- $MINGW_VERSION - mingw version
echo -- $ARCH - target arch
echo -- PATH is $PATH
echo -- using cmake command
echo $CMAKE
