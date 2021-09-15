#!/usr/bin/bash.exe

set -ex
source mingw_toolchain.sh


TOOLS_PKGS="\
	mingw-w64-${ARCH}-cmake \
	mingw-w64-${ARCH}-gcc \
	mingw-w64-${ARCH}-python3\
	mingw-w64-${ARCH}-python-mako\
	mingw-w64-${ARCH}-python-six\
	mingw-w64-${ARCH}-make\
	mingw-w64-${ARCH}-doxygen \
	git\
	svn\
	base-devel\
"
	#mingw-w64-${ARCH}-boost 
PACMAN_SYNC_DEPS=" \
	mingw-w64-${ARCH}-fftw \
	mingw-w64-${ARCH}-orc \
	mingw-w64-${ARCH}-libxml2 \
	mingw-w64-${ARCH}-libzip \
	mingw-w64-${ARCH}-fftw \
	mingw-w64-${ARCH}-libzip \
	mingw-w64-${ARCH}-libffi \
	mingw-w64-${ARCH}-glib2 \
	mingw-w64-${ARCH}-glibmm \
	mingw-w64-${ARCH}-doxygen\
	mingw-w64-${ARCH}-qt5 \
	mingw-w64-${ARCH}-zlib \
	mingw-w64-${ARCH}-breakpad-git \
	mingw-w64-${ARCH}-libusb \
"
export PKG_CONFIG_PATH=$STAGING_DIR/lib/pkgconfig

install_tools() {
	mkdir -p $WORKDIR/windres
	pushd $WORKDIR/windres
	if [ ! -f windres.exe.gz ]; then 
		wget http://swdownloads.analog.com/cse/build/windres.exe.gz
		gunzip windres.exe.gz
	fi
	popd

	pacman --noconfirm --needed -S $TOOLS_PKGS
}
install_deps() {
	$PACMAN -S $PACMAN_SYNC_DEPS
	$PACMAN -U https://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-boost-1.75.0-9-any.pkg.tar.zst 
}

create_build_status_file() {

echo "Built scopy-mingw-build-deps on Appveyor" >> $BUILD_STATUS_FILE
echo "on $(date)" >> $BUILD_STATUS_FILE
echo "url: ${APPVEYOR_URL}" >> $BUILD_STATUS_FILE
echo "api_url: ${APPVEYOR_API_URL}" >> $BUILD_STATUS_FILE
echo "acc_name: ${APPVEYOR_ACCOUNT_NAME}" >> $BUILD_STATUS_FILE
echo "prj_name: ${APPVEYOR_PROJECT_NAME}" >> $BUILD_STATUS_FILE
echo "build_id: ${APPVEYOR_BUILD_ID}" >> $BUILD_STATUS_FILE
echo "build_nr: ${APPVEYOR_BUILD_NUMBER}" >> $BUILD_STATUS_FILE
echo "build_version: ${APPVEYOR_BUILD_VERSION}" >> $BUILD_STATUS_FILE
echo "job_id: ${APPVEYOR_JOB_ID}" >> $BUILD_STATUS_FILE
echo "job_name: ${APPVEYOR_JOB_NAME}" >> $BUILD_STATUS_FILE
echo "job_nr: ${APPVEYOR_JOB_NUMBER}" >> $BUILD_STATUS_FILE
echo "job_link:  ${APPVEYOR_URL}/project/${APPVEYOR_ACCOUNT_NAME}/${APPVEYOR_PROJECT_NAME}/builds/${APPVEYOR_BUILD_ID}/job/${APPVEYOR_JOB_ID}" >> $BUILD_STATUS_FILE

echo $BUILD_STATUS_FILE

echo "Repo deps locations/files" >> $BUILD_STATUS_FILE
echo $PACMAN_REPO_DEPS >> $BUILD_STATUS_FILE
ls ${WORKDIR}/old_msys_deps_${MINGW_VERSION}
}

__clean_build_dir() {
	git clean -xdf
	rm -rf ${WORKDIR}/$CURRENT_BUILD/build-${ARCH}
	mkdir ${WORKDIR}/$CURRENT_BUILD/build-${ARCH}
	cd ${WORKDIR}/$CURRENT_BUILD/build-${ARCH}
}

__build_with_cmake() {
	INSTALL="install"
	if [ $NO_INSTALL=="TRUE" ]; then
		INSTALL=""
	fi
	pushd $WORKDIR/$CURRENT_BUILD
	__clean_build_dir
	eval $CURRENT_BUILD_POST_CLEAN
	eval $CURRENT_BUILD_PATCHES
	$CMAKE $CURRENT_BUILD_CMAKE_OPTS $WORKDIR/$CURRENT_BUILD
	eval $CURRENT_BUILD_POST_CMAKE
	$MAKE_BIN $JOBS $INSTALL
	eval $CURRENT_BUILD_POST_MAKE
	echo "$CURRENT_BUILD - $(git rev-parse --short HEAD)" >> $BUILD_STATUS_FILE
	# clear vars
	CURRENT_BUILD_CMAKE_OPTS="" 
	CURRENT_BUILD_POST_CLEAN=""
	CURRENT_BUILD_PATCHES=""
	CURRENT_BUILD_POST_CMAKE=""
	CURRENT_BUILD_POST_MAKE=""
	CURRENT_BUILD=""
	NO_INSTALL=""
	popd
}

build_log4cpp() {
	CURRENT_BUILD=log4cpp

	# this is a fix for MINGW long long long is too long - patch the config-MingW32.h
	# probably not the cleanest patch - deletes this line
	# https://github.com/orocos-toolchain/log4cpp/blob/359be7d88eb8a87f618620918c73ef1fc6e87242/include/log4cpp/config-MinGW32.h#L27
	# we need a better patch here or maybe use another repo

	CURRENT_BUILD_POST_CLEAN="
	git reset --hard &&
	sed '27d' ../include/log4cpp/config-MinGW32.h > temp && mv temp ../include/log4cpp/config-MinGW32.h;
	"
	# LOG4CPP puts dll in wrong file for MINGW - it should be in bin, but it puts it in lib so we copy it
	CURRENT_BUILD_POST_MAKE="
	mkdir -p $STAGING_DIR/bin && 
	cp $STAGING_DIR/lib/liblog4cpp.dll $STAGING_DIR/bin/liblog4cpp.dll
	"
	__build_with_cmake
}

build_volk() {
	CURRENT_BUILD=volk
	CURRENT_BUILD_POST_CLEAN="git submodule update --init"
	CURRENT_BUILD_CMAKE_OPTS="-DPYTHON_EXECUTABLE=/mingw64/bin/python3 -DENABLE_MODTOOL=OFF -DENABLE_TESTING=OFF ../"
	__build_with_cmake

}

build_gnuradio() {
	#echo gnuradio
	CURRENT_BUILD=gnuradio

	# Set -fno-asynchronous-unwind-tables to avoid these error messages:
	# C:\Users\appveyor\AppData\Local\Temp\1\ccO00eqH.s: Assembler messages:
	# C:\Users\appveyor\AppData\Local\Temp\1\ccO00eqH.s:17939: Error: invalid register for .seh_savexmm
	# might be related to the liborc library though ...

	CURRENT_BUILD_CMAKE_OPTS="-DENABLE_GR_DIGITAL:BOOL=OFF \
		-DENABLE_GR_DTV:BOOL=OFF \
		-DENABLE_GR_AUDIO:BOOL=OFF \
		-DENABLE_GR_CHANNELS:BOOL=OFF \
		-DENABLE_GR_TRELLIS:BOOL=OFF \
		-DENABLE_GR_VOCODER:BOOL=OFF \
		-DENABLE_GR_FEC:BOOL=OFF \
		-DENABLE_DOXYGEN:BOOL=OFF \
		-DENABLE_TESTING:BOOL=OFF \
		-DENABLE_INTERNAL_VOLK:BOOL=OFF \
		-DCMAKE_C_FLAGS=-fno-asynchronous-unwind-tables \
		-DPYTHON_EXECUTABLE=/mingw64/bin/python3 \
		"
	__build_with_cmake
}

build_libiio() {
	CURRENT_BUILD=libiio
	CURRENT_BUILD_CMAKE_OPTS="\
		${RC_COMPILER_OPT} \
		-DENABLE_IPV6=OFF \
		-DWITH_USB_BACKEND=ON \
		-DWITH_SERIAL_BACKEND=OFF \
		-DWITH_TESTS:BOOL=OFF \
		-DWITH_DOC:BOOL=OFF \
		-DCSHARP_BINDINGS:BOOL=OFF \
		-DPYTHON_BINDINGS:BOOL=OFF \
	"
	__build_with_cmake
}

build_glog() {
	CURRENT_BUILD=glog
	CURRENT_BUILD_CMAKE_OPTS="\
	-DWITH_GFLAGS=OFF \
	-DBUILD_SHARED_LIBS=ON \
	"
	__build_with_cmake
}

build_libm2k() {
	CURRENT_BUILD=libm2k
	CURRENT_BUILD_CMAKE_OPTS="\
		-DENABLE_PYTHON=OFF\
		-DENABLE_CSHARP=OFF\
		-DBUILD_EXAMPLES=OFF\
		-DENABLE_TOOLS=OFF\
		-DENABLE_LOG=ON\
		-DINSTALL_UDEV_RULES=OFF\
		"
	__build_with_cmake
}

build_libad9361() {
	echo "### Building libad9361 - branch $LIBAD9361_BRANCH"
	CURRENT_BUILD=libad9361
	__build_with_cmake
}

build_griio() {
	echo "### Building gr-iio - branch $GRIIO_BRANCH"

	CURRENT_BUILD=gr-iio
	# -D_hypot=hypot: http://boost.2283326.n4.nabble.com/Boost-Python-Compile-Error-s-GCC-via-MinGW-w64-td3165793.html#a3166757
	CURRENT_BUILD_CMAKE_OPTS="-DCMAKE_CXX_FLAGS=-D_hypot=hypot -DPYTHON_EXECUTABLE=/mingw64/bin/python3 "
	__build_with_cmake

}

build_grm2k() {
	echo "### Building gr-m2k - branch $GRM2K_BRANCH"
	CURRENT_BUILD=gr-m2k
	CURRENT_BUILD_CMAKE_OPTS="-DPYTHON_EXECUTABLE=/mingw64/bin/python3 "
	__build_with_cmake
}

build_grscopy() {
	echo "### Building gr-scopy - branch $GRSCOPY_BRANCH"
	CURRENT_BUILD=gr-scopy
	CURRENT_BUILD_CMAKE_OPTS="-DPYTHON_EXECUTABLE=/mingw64/bin/python3 "
	__build_with_cmake
}

build_libsigrokdecode() {
	echo "### Building libsigrokdecode - branch $LIBSIGROKDECODE_BRANCH"
	CURRENT_BUILD=libsigrokdecode

	pushd $WORKDIR/libsigrokdecode
	git reset --hard
	git clean -xdf

	rm -rf ${WORKDIR}/libsigrokdecode/build-${ARCH}
	mkdir -p ${WORKDIR}/libsigrokdecode/build-${ARCH}
	cd ${WORKDIR}/libsigrokdecode

	patch -p1 < ${WORKDIR}/sigrokdecode-windows-fix.patch
	./autogen.sh
	cd build-${ARCH}

	CPPFLAGS="-DLIBSIGROKDECODE_EXPORT=1" ../configure ${AUTOCONF_OPTS}
	$MAKE_BIN $JOBS install
	echo "$CURRENT_BUILD - $(git rev-parse --short HEAD)" >> $BUILD_STATUS_FILE
	popd
}

build_qwt() {
	echo "### Building qwt - branch $QWT_BRANCH"
	CURRENT_BUILD=qwt
	svn checkout svn://svn.code.sf.net/p/qwt/code/branches/qwt-6.1-multiaxes $CURRENT_BUILD
	pushd $CURRENT_BUILD
	svn patch $WORKDIR/qwt-config-svn.patch

	$QMAKE
	make $JOBS 
	make INSTALL_ROOT="$STAGING_DIR" $JOBS install
	cp $STAGING_DIR/lib/qwt.dll $STAGING_DIR/bin/qwt.dll
	echo "$CURRENT_BUILD - $(git rev-parse --short HEAD)" >> $BUILD_STATUS_FILE
	popd
}

build_libtinyiiod() {
	echo "### Building libtinyiiod - branch $LIBTINYIIOD_BRANCH"
	CURRENT_BUILD=libtinyiiod
	CURRENT_BUILD_CMAKE_OPTS="-DBUILD_EXAMPLES=OFF"
	__build_with_cmake
}

build_scopy() {
	CURRENT_BUILD=scopy
	NO_INSTALL="TRUE"
	CURRENT_BUILD_CMAKE_OPTS="$RC_COMPILER_OPT \
	-DBREAKPAD_HANDLER=ON \
	-DWITH_DOC=ON \
	-DPYTHON_EXECUTABLE=/$MINGW_VERSION/bin/python3.exe \
	"
	__build_with_cmake
}

package_and_push() {
if [ -z $APPVEYOR ]; then
	echo "Appveyor environment not detected"
	return
fi

echo "" >> $BUILD_STATUS_FILE
echo "$PACMAN -Qe output - all explicitly installed packages on build machine" >> $BUILD_STATUS_FILE
$PACMAN -Qe >> $BUILD_STATUS_FILE
echo "pacman -Qm output - all packages from nonsync sources" >> $BUILD_STATUS_FILE
$PACMAN -Qm >> $BUILD_STATUS_FILE

# Fix DLLs installed in the wrong path
#mv ${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwt.dll \
#	${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwtpolar.dll \
#	${WORKDIR}/msys64/${MINGW_VERSION}/bin

#rm -rf ${WORKDIR}/msys64/${MINGW_VERSION}/doc \
#	${WORKDIR}/msys64/${MINGW_VERSION}/share/doc \
#	${WORKDIR}/msys64/${MINGW_VERSION}/lib/*.la

echo "### Creating archive ... "
tar cavf ${WORKDIR}/scopy-${MINGW_VERSION}-build-deps.tar.xz -C ${WORKDIR} msys64
appveyor PushArtifact $BUILD_STATUS_FILE
$PACMAN -Q > /tmp/AllInstalledPackages
appveyor PushArtifact /tmp/AllInstalledPackages
echo -n ${PACMAN_SYNC_DEPS} > ${WORKDIR}/scopy-$MINGW_VERSION-build-deps-pacman.txt
}

install_tools
install_deps
create_build_status_file
build_glog
build_libiio
build_libad9361
build_libm2k
build_log4cpp
build_volk
build_gnuradio
build_griio
build_grscopy
build_grm2k
build_qwt
build_libsigrokdecode
build_libtinyiiod
build_scopy # for testing
package_and_push
