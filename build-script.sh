#!/bin/sh
# Usage: build-script.sh bitcoind-port
set -e
set -o xtrace

git clean -f -x -d

cd src
make -f makefile.unix -j2 test_bitcoin USE_UPNP=-
./test_bitcoin
make -f makefile.unix -j2 USE_UPNP=-
mkdir out && cp bitcoind test_bitcoin out/

git apply /mnt/test-scripts/bitcoind-comparison.patch
make -f makefile.unix -j2 USE_UPNP=-
./bitcoind -connect=0.0.0.0 -datadir=/home/ubuntu/.bitcoin -rpcuser=user -rpcpassword=pass -listen -port=$1&
BITCOIND_PID=$!
while [ "x`cat /home/ubuntu/.bitcoin/debug.log | grep 'Done loading' | wc -l`" = "x0" ]; do sleep 1; done
LD_PRELOAD=/usr/lib/jvm/java-6-openjdk/jre/lib/i386/jli/libjli.so java -jar /mnt/test-scripts/BitcoinjBitcoindComparisonTool.jar $1
kill -9 $BITCOIND_PID
rm -rf /home/ubuntu/.bitcoin/*

cd ..
git reset --hard

qmake bitcoin-qt.pro BITCOIN_QT_TEST=1 USE_UPNP=-
make -j2
./bitcoin-qt_test

mkdir out
mv bitcoin-qt_test out/
make clean

qmake bitcoin-qt.pro USE_UPNP=-
make -j2
mv bitcoin-qt out/
make clean

cd src
make -f makefile.unix clean

make -f makefile.linux-mingw -j2 DEPSDIR=/mnt/mingw test_bitcoin.exe
./test_bitcoin.exe
make -f makefile.linux-mingw -j2 DEPSDIR=/mnt/mingw USE_UPNP=0

cp bitcoind.exe test_bitcoin.exe out/

git apply /mnt/test-scripts/bitcoind-comparison.patch
make -f makefile.linux-mingw -j2 DEPSDIR=/mnt/mingw USE_UPNP=0
./bitcoind.exe -connect=0.0.0.0 -datadir=/home/ubuntu/.bitcoin -rpcuser=user -rpcpassword=pass -listen -port=$1&
BITCOIND_PID=$!
while [ "x`cat /home/ubuntu/.bitcoin/debug.log | grep 'Done loading' | wc -l`" = "x0" ]; do sleep 1; done
LD_PRELOAD=/usr/lib/jvm/java-6-openjdk/jre/lib/i386/jli/libjli.so java -jar /mnt/test-scripts/BitcoinjBitcoindComparisonTool.jar $1
kill -9 $BITCOIND_PID
rm -rf /home/ubuntu/.bitcoin/*
git reset --hard

make -f makefile.linux-mingw clean
mv out/* ./
rm -r out
cd ..

/mnt/mingw/qt/src/bin/qmake -spec unsupported/win32-g++-cross BITCOIN_QT_TEST=1 MINIUPNPC_LIB_PATH=/mnt/mingw/miniupnpc/ MINIUPNPC_INCLUDE_PATH=/mnt/mingw/ BDB_LIB_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BDB_INCLUDE_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BOOST_LIB_PATH=/mnt/mingw/boost_1_50_0/stage/lib BOOST_INCLUDE_PATH=/mnt/mingw/boost_1_50_0/ BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=/mnt/mingw/openssl-1.0.1b OPENSSL_INCLUDE_PATH=/mnt/mingw/openssl-1.0.1b/include/ QRENCODE_LIB_PATH=/mnt/mingw/qrencode-3.2.0/.libs QRENCODE_INCLUDE_PATH=/mnt/mingw/qrencode-3.2.0 USE_QRCODE=1 INCLUDEPATH=/mnt/mingw DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 QMAKE_MOC=/mnt/mingw/qt/src/bin/moc QMAKE_UIC=/mnt/mingw/qt/src/bin/uic
make -j2
./release/bitcoin-qt_test.exe
mv release/bitcoin-qt_test.exe out/

make clean
/mnt/mingw/qt/src/bin/qmake -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=/mnt/mingw/miniupnpc/ MINIUPNPC_INCLUDE_PATH=/mnt/mingw/ BDB_LIB_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BDB_INCLUDE_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BOOST_LIB_PATH=/mnt/mingw/boost_1_50_0/stage/lib BOOST_INCLUDE_PATH=/mnt/mingw/boost_1_50_0/ BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=/mnt/mingw/openssl-1.0.1b OPENSSL_INCLUDE_PATH=/mnt/mingw/openssl-1.0.1b/include/ QRENCODE_LIB_PATH=/mnt/mingw/qrencode-3.2.0/.libs QRENCODE_INCLUDE_PATH=/mnt/mingw/qrencode-3.2.0 USE_QRCODE=1 INCLUDEPATH=/mnt/mingw DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 QMAKE_MOC=/mnt/mingw/qt/src/bin/moc QMAKE_UIC=/mnt/mingw/qt/src/bin/uic
make -j2
mv release/bitcoin-qt.exe out/
make clean

mv out/* ./
rm -r out
