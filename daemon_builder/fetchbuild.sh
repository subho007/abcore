#! /bin/bash
set -e

url=$1
mkdir build
cd build
curl -L $url | tar xz &> /dev/null
src_dir=$(ls)
cd $src_dir
patch -p1 < /repo/daemon_builder/0001-android-patches.patch

OLD_PATH=$PATH

function build() {

    toolchain=$1
    target_host=$2
    export PATH=/opt/$toolchain/bin:${OLD_PATH}
    export AR=$target_host-ar
    export AS=$target_host-clang
    export CC=$target_host-clang
    export CXX=$target_host-clang++
    export LD=$target_host-ld
    export STRIP=$target_host-strip
    export LDFLAGS="-pie -static-libstdc++"

    cd depends
    make HOST=$target_host NO_QT=1

    cd ..

    ./autogen.sh
    ./configure --prefix=$PWD/depends/$target_host ac_cv_c_bigendian=no --disable-bench --enable-experimental-asm --disable-tests --disable-man --without-utils --without-libs --with-daemon

    make -j4
    make install

    tarfilename="${url##*/}"

    $STRIP depends/$target_host/bin/bitcoind

    tar -zcf /${target_host}_${tarfilename} -C depends/$target_host/bin bitcoind
    make clean
}

build x86_64-clang x86_64-linux-android
build aarch64-linux-android-clang aarch64-linux-android
build x86-clang i686-linux-android
build arm-linux-androideabi-clang arm-linux-androideabi
