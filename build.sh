#!/usr/bin/bash.exe

LIBIIO_BRANCH=master
LIBAD9361_BRANCH=master
LIBM2K_BRANCH=master
GRIIO_BRANCH=upgrade-3.8
GNURADIO_FORK=analogdevicesinc
GNURADIO_BRANCH=ming-3.8-clean
GRSCOPY_BRANCH=master
GRM2K_BRANCH=master
QWT_BRANCH=qwt-6.1-multiaxes
QWTPOLAR_BRANCH=master # not used
LIBSIGROKDECODE_BRANCH=master

#TODO: make each dep install it's own deps
# Exit immediately if an error occurs
set -e

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32

WORKDIR=${PWD}
JOBS=-j3

CC=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-gcc.exe
CXX=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-g++.exe
CMAKE_OPTS="
	-DCMAKE_C_COMPILER:FILEPATH=${CC} \
	-DCMAKE_CXX_COMPILER:FILEPATH=${CXX} \
	-DPKG_CONFIG_EXECUTABLE=/$MINGW_VERSION/bin/pkg-config.exe \
	-DCMAKE_INSTALL_PREFIX=/${MINGW_VERSION}\
	-DCMAKE_PREFIX_PATH=/c/msys64/$MINGW_VERSION/lib/cmake \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"
AUTOCONF_OPTS="--prefix=/msys64/${MINGW_VERSION} \
	--host=${ARCH}-w64-mingw32 \
	--enable-shared \
	--disable-static"

if [ ${ARCH} == "i686" ]
then
	RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/c/windres.exe"
else
	RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/c/msys64/mingw64/bin/windres.exe"
fi
install_deps() {
echo "### Download and installed precompiled GNURadio ... "
wget "https://ci.appveyor.com/api/projects/$GNURADIO_FORK/gnuradio/artifacts/gnuradio-$MINGW_VERSION-deps.txt?branch=$GNURADIO_BRANCH&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH" -O /tmp/gnuradio-$MINGW_VERSION-deps.txt
wget "https://ci.appveyor.com/api/projects/$GNURADIO_FORK/gnuradio/artifacts/gnuradio-$MINGW_VERSION.tar.xz?branch=$GNURADIO_BRANCH&job=Environment: MINGW_VERSION=$MINGW_VERSION, ARCH=$ARCH" -O /tmp/gnuradio-$MINGW_VERSION.tar.xz
cd $WORKDIR
tar xJf /tmp/gnuradio-$MINGW_VERSION.tar.xz
cd /c
tar xJf /tmp/gnuradio-$MINGW_VERSION.tar.xz

GNURADIO_DEPS=$(</tmp/gnuradio-$MINGW_VERSION-deps.txt)

#	mingw-w64-$ARCH-qt \
PACMAN_SYNC_DEPS="
	$GNURADIO_DEPS \
	mingw-w64-$ARCH-libxml2 \
	mingw-w64-$ARCH-libzip \
	mingw-w64-$ARCH-fftw \
	mingw-w64-$ARCH-libzip \
	mingw-w64-$ARCH-libffi \
	mingw-w64-$ARCH-glib2 \
	mingw-w64-$ARCH-glibmm \
	mingw-w64-$ARCH-doxygen\
"


PACMAN_REPO_DEPS="
${WORKDIR}/old_msys_deps_${MINGW_VERSION}/mingw-w64-$ARCH-libusb-1.0.21-2-any.pkg.tar.xz \
${WORKDIR}/old_msys_deps_${MINGW_VERSION}/mingw-w64-$ARCH-boost-1.72.0-3-any.pkg.tar.zst \
${WORKDIR}/old_msys_deps_${MINGW_VERSION}/mingw-w64-$ARCH-qt5-5.14.2-3-any.pkg.tar.zst \
"
ls ${WORKDIR}/old_msys_deps_${MINGW_VERSION}

echo "### Installing dependencies ... "
pacman --noconfirm --needed -Sy $PACMAN_SYNC_DEPS
pacman --noconfirm -U  $PACMAN_REPO_DEPS

# Fix Qt5 spec files
sed -i "s/\$\${CROSS_COMPILE}/${ARCH}-w64-mingw32-/" /${MINGW_VERSION}/share/qt5/mkspecs/win32-g++/qmake.conf
}

build_libiio() {
	echo "### Building libiio - branch $LIBIIO_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/libiio.git -b $LIBIIO_BRANCH ${WORKDIR}/libiio

	mkdir ${WORKDIR}/libiio/build-${ARCH}
	cd ${WORKDIR}/libiio/build-${ARCH}
	# Download a 32-bit version of windres.exe

	cd /c
	wget http://swdownloads.analog.com/cse/build/windres.exe.gz
	gunzip windres.exe.gz
	cd ${WORKDIR}/libiio/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		${RC_COMPILER_OPT} \
		-DWITH_TESTS:BOOL=OFF \
		-DWITH_DOC:BOOL=OFF \
		-DCSHARP_BINDINGS:BOOL=OFF \
		-DPYTHON_BINDINGS:BOOL=OFF \
		${WORKDIR}/libiio

	make ${JOBS} install
	DESTDIR=${WORKDIR} make ${JOBS} install
}

build_libm2k() {
	echo "### Building libm2k - branch $LIBM2K_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/libm2k.git -b $LIBM2K_BRANCH ${WORKDIR}/libm2k

	mkdir ${WORKDIR}/libm2k/build-${ARCH}
	cd ${WORKDIR}/libm2k/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		-DENABLE_PYTHON=OFF\
		-DENABLE_CSHARP=OFF\
		-DENABLE_EXAMPLES=OFF\
		-DENABLE_TOOLS=OFF\
		-DINSTALL_UDEV_RULES=OFF\
		${WORKDIR}/libm2k

	make ${JOBS} install
	DESTDIR=${WORKDIR} make ${JOBS} install

}

build_libad9361() {
	echo "### Building libad9361 - branch $LIBAD9361_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/libad9361-iio.git -b $LIBAD9361_BRANCH ${WORKDIR}/libad9361

	mkdir ${WORKDIR}/libad9361/build-${ARCH}
	cd ${WORKDIR}/libad9361/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		${WORKDIR}/libad9361

	make $JOBS install
	DESTDIR=${WORKDIR} make $JOBS install
}

build_griio() {
	echo "### Building gr-iio - branch $GRIIO_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/gr-iio.git -b $GRIIO_BRANCH ${WORKDIR}/gr-iio

	mkdir ${WORKDIR}/gr-iio/build-${ARCH}
	cd ${WORKDIR}/gr-iio/build-${ARCH}

	# -D_hypot=hypot: http://boost.2283326.n4.nabble.com/Boost-Python-Compile-Error-s-GCC-via-MinGW-w64-td3165793.html#a3166757
	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		-DCMAKE_CXX_FLAGS="-D_hypot=hypot" \
		${WORKDIR}/gr-iio

	make $JOBS install
	DESTDIR=${WORKDIR} make $JOBS install
}

build_grm2k() {
	echo "### Building gr-m2k - branch $GRM2K_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/gr-m2k.git -b $GRM2K_BRANCH ${WORKDIR}/gr-m2k
	mkdir ${WORKDIR}/gr-m2k/build-${ARCH}
	cd ${WORKDIR}/gr-m2k/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		${WORKDIR}/gr-m2k

	make $JOBS install
	DESTDIR=${WORKDIR} make $JOBS install

}

build_grscopy() {
	echo "### Building gr-scopy - branch $GRSCOPY_BRANCH"

	git clone --depth 1 https://github.com/analogdevicesinc/gr-scopy.git -b $GRSCOPY_BRANCH ${WORKDIR}/gr-scopy
	mkdir ${WORKDIR}/gr-scopy/build-${ARCH}
	cd ${WORKDIR}/gr-scopy/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		${WORKDIR}/gr-scopy

	make $JOBS install
	DESTDIR=${WORKDIR} make $JOBS install
}

build_libsigrokdecode() {
	echo "### Building libsigrokdecode - branch $LIBSIGROKDECODE_BRANCH"
	git clone --depth 1 https://github.com/sigrokproject/libsigrokdecode.git -b $LIBSIGROKDECODE_BRANCH ${WORKDIR}/libsigrokdecode

	mkdir -p ${WORKDIR}/libsigrokdecode/build-${ARCH}
	cd ${WORKDIR}/libsigrokdecode

	patch -p1 < ${WORKDIR}/sigrokdecode-windows-fix.patch
	./autogen.sh
	cd build-${ARCH}

	CPPFLAGS="-DLIBSIGROKDECODE_EXPORT=1" ../configure ${AUTOCONF_OPTS}
	make $JOBS install
	DESTDIR=${WORKDIR} make $JOBS install
}

build_qwt() {
	echo "### Building qwt - branch $QWT_BRANCH"

	git clone --depth 1 https://github.com/osakared/qwt.git -b $QWT_BRANCH ${WORKDIR}/qwt
	cd ${WORKDIR}/qwt

	# Disable components that we won't build
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtMathML$/#/g" qwtconfig.pri
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtDesigner$/#/g" qwtconfig.pri
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtExamples$/#/g" qwtconfig.pri

	# Fix prefix
	sed -i "s/^\\s*QWT_INSTALL_PREFIX.*$/QWT_INSTALL_PREFIX=\"\"/g" qwtconfig.pri

	cd ${WORKDIR}/qwt/src
	qmake
	make INSTALL_ROOT="/c/msys64/${MINGW_VERSION}" $JOBS -f Makefile.Release install
	make INSTALL_ROOT="${WORKDIR}/msys64/${MINGW_VERSION}" $JOBS -f Makefile.Release install
}

build_qwtpolar() {
	echo "### Building qwtpolar - branch $QWTPOLAR_BRANCH"
	mkdir -p ${WORKDIR}/qwtpolar
	cd ${WORKDIR}/qwtpolar

	wget https://downloads.sourceforge.net/project/qwtpolar/qwtpolar/1.1.1/qwtpolar-1.1.1.tar.bz2 -O- \
		| tar xj --strip-components=1 -C ${WORKDIR}/qwtpolar

	patch -p1 < ${WORKDIR}/qwtpolar-qwt-6.1-compat.patch

	# Disable components that we won't build
	sed -i "s/^QWT_POLAR_CONFIG\\s*+=\\s*QwtPolarDesigner$/#/g" qwtpolarconfig.pri
	sed -i "s/^QWT_POLAR_CONFIG\\s*+=\\s*QwtPolarExamples$/#/g" qwtpolarconfig.pri

	# Fix prefix
	sed -i "s/^\\s*QWT_POLAR_INSTALL_PREFIX.*$/QWT_POLAR_INSTALL_PREFIX=\"\"/g" qwtpolarconfig.pri

	cd ${WORKDIR}/qwtpolar/src
	qmake LIBS+="-lqwt"
	make INSTALL_ROOT="/c/msys64/${MINGW_VERSION}" $JOBS -f Makefile.Release install
	make INSTALL_ROOT="${WORKDIR}/msys64/${MINGW_VERSION}" $JOBS -f Makefile.Release install
}

install_deps
build_libiio
build_libad9361
build_libm2k
build_griio
build_grscopy
build_grm2k
build_qwt
build_qwtpolar
build_libsigrokdecode

# Fix DLLs installed in the wrong path
mv ${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwt.dll \
	${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwtpolar.dll \
	${WORKDIR}/msys64/${MINGW_VERSION}/bin

rm -rf ${WORKDIR}/msys64/${MINGW_VERSION}/doc \
	${WORKDIR}/msys64/${MINGW_VERSION}/share/doc \
	${WORKDIR}/msys64/${MINGW_VERSION}/lib/*.la

echo "### Creating archive ... "
tar cavf ${WORKDIR}/scopy-${MINGW_VERSION}-build-deps.tar.xz -C ${WORKDIR} msys64

echo -n ${PACMAN_SYNC_DEPS} > ${WORKDIR}/scopy-$MINGW_VERSION-build-deps-pacman.txt


