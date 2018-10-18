#!/usr/bin/bash.exe

# Exit immediately if an error occurs
set -e

export PATH=/bin:/usr/bin:/${MINGW_VERSION}/bin:/c/Program\ Files/Git/cmd:/c/Windows/System32

WORKDIR=${PWD}

JOBS=3

CC=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-gcc.exe
CXX=/${MINGW_VERSION}/bin/${ARCH}-w64-mingw32-g++.exe
CMAKE_OPTS="-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/${MINGW_VERSION} \
	-DCMAKE_C_COMPILER:FILEPATH=${CC} \
	-DCMAKE_CXX_COMPILER:FILEPATH=${CXX} \
	-DPKG_CONFIG_EXECUTABLE:FILEPATH=/${MINGW_VERSION}/bin/pkg-config.exe"
AUTOCONF_OPTS="--prefix=/msys64/${MINGW_VERSION} \
	--host=${ARCH}-w64-mingw32 \
	--enable-shared \
	--disable-static"

if [ ${ARCH} == "i686" ]
then
	RC_COMPILER_OPT="-DCMAKE_RC_COMPILER=/c/windres.exe"
else
	RC_COMPILER_OPT=""
fi

DEPENDENCIES="mingw-w64-${ARCH}-libxml2 \
	mingw-w64-${ARCH}-libusb \
	mingw-w64-${ARCH}-boost \
	mingw-w64-${ARCH}-fftw \
	mingw-w64-${ARCH}-libzip \
	mingw-w64-${ARCH}-python3 \
	mingw-w64-${ARCH}-fftw \
	mingw-w64-${ARCH}-libzip \
	mingw-w64-${ARCH}-glib2 \
	mingw-w64-${ARCH}-glibmm \
	mingw-w64-${ARCH}-pkg-config \
	mingw-w64-${ARCH}-matio"

# Remove dependencies that prevent us from upgrading to GCC 6.2
pacman -Rs --noconfirm \
	mingw-w64-${ARCH}-gcc-ada \
	mingw-w64-${ARCH}-gcc-fortran \
	mingw-w64-${ARCH}-gcc-libgfortran \
	mingw-w64-${ARCH}-gcc-objc

# Remove existing file that causes GCC install to fail
rm /${MINGW_VERSION}/etc/gdbinit

# Update to GCC 6.2 and install build-time dependencies
pacman --force --noconfirm -Sy \
	mingw-w64-${ARCH}-gcc \
	mingw-w64-${ARCH}-cmake \
	mingw-w64-${ARCH}-doxygen \
	autoconf \
	automake-wrapper

pacman -U --noconfirm http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-llvm-5.0.0-3-any.pkg.tar.xz http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-clang-5.0.0-3-any.pkg.tar.xz      

# Install an older version of icu
#pacman -U --noconfirm http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-icu-58.2-3-any.pkg.tar.xz
#pacman -U --noconfirm http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-icu-debug-libs-58.2-3-any.pkg.tar.xz

# Install dependencies
pacman --force --noconfirm -Sy ${DEPENDENCIES}

# Install an older version of Qt due to uic.exe issues
wget -q http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-qt5-5.9.1-1-any.pkg.tar.xz
pacman -U --force --noconfirm mingw-w64-${ARCH}-qt5-5.9.1-1-any.pkg.tar.xz
pacman -U --noconfirm http://repo.msys2.org/mingw/${ARCH}/mingw-w64-${ARCH}-curl-7.61.1-2-any.pkg.tar.xz

# Fix Qt5 spec files
sed -i "s/\$\${CROSS_COMPILE}/${ARCH}-w64-mingw32-/" /${MINGW_VERSION}/share/qt5/mkspecs/win32-g++/qmake.conf

build_libiio() {
	git clone --depth 1 https://github.com/analogdevicesinc/libiio.git ${WORKDIR}/libiio

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
		-DWITH_MATLAB_BINDINGS:BOOL=OFF \
		-DCSHARP_BINDINGS:BOOL=OFF \
		-DPYTHON_BINDINGS:BOOL=OFF \
		${WORKDIR}/libiio

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_libad9361() {
	git clone --depth 1 https://github.com/analogdevicesinc/libad9361-iio.git ${WORKDIR}/libad9361

	mkdir ${WORKDIR}/libad9361/build-${ARCH}
	cd ${WORKDIR}/libad9361/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		${WORKDIR}/libad9361

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_libsigrok() {
	git clone --depth 1 https://github.com/sigrokproject/libsigrok.git ${WORKDIR}/libsigrok

	mkdir ${WORKDIR}/libsigrok/build-${ARCH}
	cd ${WORKDIR}/libsigrok/build-${ARCH}

	../autogen.sh
	CPPFLAGS="-DLIBSIGROK_EXPORT=1" ../configure ${AUTOCONF_OPTS} \
		--without-libusb \
		--enable-all-drivers=no

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install

	# For some reason, Scopy chokes if these are present in enums.hpp
	sed -i "s/static const Quantity \* const DIFFERENCE;$//g" ${WORKDIR}/msys64/${MINGW_VERSION}/include/libsigrokcxx/enums.hpp
	sed -i "s/static const QuantityFlag \* const RELATIVE;$//g" ${WORKDIR}/msys64/${MINGW_VERSION}/include/libsigrokcxx/enums.hpp
}

build_libsigrokdecode() {
	mkdir -p ${WORKDIR}/libsigrokdecode/build-${ARCH}
	cd ${WORKDIR}/libsigrokdecode

	wget http://sigrok.org/download/source/libsigrokdecode/libsigrokdecode-0.4.1.tar.gz -O- \
		| tar xz --strip-components=1 -C ${WORKDIR}/libsigrokdecode

	patch -p1 < ${WORKDIR}/sigrokdecode-windows-fix.patch
	cd build-${ARCH}

	CPPFLAGS="-DLIBSIGROKDECODE_EXPORT=1" ../configure ${AUTOCONF_OPTS}

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_markdown() {
	mkdir -p ${WORKDIR}/markdown
	cd ${WORKDIR}/markdown

	wget https://pypi.python.org/packages/1d/25/3f6d2cb31ec42ca5bd3bfbea99b63892b735d76e26f20dd2dcc34ffe4f0d/Markdown-2.6.8.tar.gz -O- \
		| tar xz --strip-components=1 -C ${WORKDIR}/markdown

	python2 setup.py build
	python2 setup.py install
}

build_cheetah() {
	mkdir -p ${WORKDIR}/cheetah
	cd ${WORKDIR}/cheetah

	wget https://pypi.python.org/packages/cd/b0/c2d700252fc251e91c08639ff41a8a5203b627f4e0a2ae18a6b662ab32ea/Cheetah-2.4.4.tar.gz -O- \
		| tar xz --strip-components=1 -C ${WORKDIR}/cheetah

	python2 setup.py build
	python2 setup.py install
}

build_libvolk() {
	mkdir -p ${WORKDIR}/libvolk/build-${ARCH}
	cd ${WORKDIR}/libvolk/build-${ARCH}

	wget http://libvolk.org/releases/volk-1.3.tar.gz -O- \
		| tar xz --strip-components=1 -C ${WORKDIR}/libvolk

	cmake -G 'Unix Makefiles' ${CMAKE_OPTS} ${WORKDIR}/libvolk

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_gnuradio() {
	git clone --depth 1 https://github.com/analogdevicesinc/gnuradio.git -b scopy ${WORKDIR}/gnuradio

	mkdir ${WORKDIR}/gnuradio/build-${ARCH}
	cd ${WORKDIR}/gnuradio/build-${ARCH}

	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		-DENABLE_GR_DIGITAL:BOOL=OFF \
		-DENABLE_GR_DTV:BOOL=OFF \
		-DENABLE_GR_ATSC:BOOL=OFF \
		-DENABLE_GR_AUDIO:BOOL=OFF \
		-DENABLE_GR_CHANNELS:BOOL=OFF \
		-DENABLE_GR_NOAA:BOOL=OFF \
		-DENABLE_GR_PAGER:BOOL=OFF \
		-DENABLE_GR_TRELLIS:BOOL=OFF \
		-DENABLE_GR_VOCODER:BOOL=OFF \
		-DENABLE_GR_FEC:BOOL=OFF \
		-DENABLE_INTERNAL_VOLK:BOOL=OFF \
		${WORKDIR}/gnuradio

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_qwt() {
	git clone --depth 1 https://github.com/osakared/qwt.git -b qwt-6.1-multiaxes ${WORKDIR}/qwt
	cd ${WORKDIR}/qwt

	# Disable components that we won't build
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtMathML$/#/g" qwtconfig.pri
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtDesigner$/#/g" qwtconfig.pri
	sed -i "s/^QWT_CONFIG\\s*+=\\s*QwtExamples$/#/g" qwtconfig.pri

	# Fix prefix
	sed -i "s/^\\s*QWT_INSTALL_PREFIX.*$/QWT_INSTALL_PREFIX=\"\"/g" qwtconfig.pri

	cd ${WORKDIR}/qwt/src
	qmake
	make INSTALL_ROOT="/c/msys64/${MINGW_VERSION}" -j ${JOBS} -f Makefile.Release install
	make INSTALL_ROOT="${WORKDIR}/msys64/${MINGW_VERSION}" -j ${JOBS} -f Makefile.Release install
}

build_qwtpolar() {
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
	make INSTALL_ROOT="/c/msys64/${MINGW_VERSION}" -j ${JOBS} -f Makefile.Release install
	make INSTALL_ROOT="${WORKDIR}/msys64/${MINGW_VERSION}" -j ${JOBS} -f Makefile.Release install
}

build_griio() {
	git clone --depth 1 https://github.com/analogdevicesinc/gr-iio.git ${WORKDIR}/gr-iio

	mkdir ${WORKDIR}/gr-iio/build-${ARCH}
	cd ${WORKDIR}/gr-iio/build-${ARCH}

	# -D_hypot=hypot: http://boost.2283326.n4.nabble.com/Boost-Python-Compile-Error-s-GCC-via-MinGW-w64-td3165793.html#a3166757
	cmake -G 'Unix Makefiles' \
		${CMAKE_OPTS} \
		-DCMAKE_CXX_FLAGS="-D_hypot=hypot" \
		${WORKDIR}/gr-iio

	make -j ${JOBS} install
	DESTDIR=${WORKDIR} make -j ${JOBS} install
}

build_markdown
build_cheetah
build_libvolk
build_gnuradio
build_libiio
build_libad9361
build_griio
build_qwt
build_qwtpolar
build_libsigrok
build_libsigrokdecode

# Fix DLLs installed in the wrong path
mv ${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwt.dll \
	${WORKDIR}/msys64/${MINGW_VERSION}/lib/qwtpolar.dll \
	${WORKDIR}/msys64/${MINGW_VERSION}/bin

rm -rf ${WORKDIR}/msys64/${MINGW_VERSION}/doc \
	${WORKDIR}/msys64/${MINGW_VERSION}/share/doc \
	${WORKDIR}/msys64/${MINGW_VERSION}/lib/*.la

tar cavf ${WORKDIR}/scopy-${MINGW_VERSION}-build-deps.tar.xz -C ${WORKDIR} msys64

echo -n ${DEPENDENCIES} > ${WORKDIR}/dependencies.txt
