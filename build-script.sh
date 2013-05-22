#!/bin/sh
# Usage: build-script.sh bitcoind-port rpc-port
set -e
set -o xtrace

# Clean up old bitcoinds to keep this script from hanging
BITCOIND_PID=`ps aux | grep bitcoin | grep "\-port=$1 -rpcport=$2" | awk '{ print $2 }'`
if [ "$BITCOIND_PID" != "" ]; then
	kill -9 $BITCOIND_PID
fi

git clean -f -x -d

cd src
# Work around broken leveldb makefile (doesnt work with CXXFLAGS)
cd leveldb
make libleveldb.a libmemenv.a
cd ..
# First run test_bitcoin with the bitcoind-comparison patch
# This makes lcov happy (we cant have coverage from two different versions of main.o)
# and makes sure that the patch is still sane (well...barely) on this branch
git apply ../contrib/test-patches/*.patch
make -f makefile.unix -j6 test_bitcoin USE_UPNP=- CXXFLAGS=--coverage LDFLAGS=--coverage
lcov -c -i -d `pwd` -b `pwd` -o baseline.info
./test_bitcoin
lcov -c -d `pwd` -b `pwd` -t test_bitcoin -o test_bitcoin.info
lcov -z -d `pwd`

make -f makefile.unix -j6 USE_UPNP=- CXXFLAGS=--coverage LDFLAGS=--coverage
rm -rf /home/ubuntu/.bitcoin/*
rm -f /home/ubuntu/.bitcoin/.lock
./bitcoind -connect=0.0.0.0 -datadir=/home/ubuntu/.bitcoin -rpcuser=user -rpcpassword=pass -listen -port=$1 -rpcport=$2 -keypool=3 -debug -logtimestamps &
BITCOIND_PID=$!
while [ "x`cat /home/ubuntu/.bitcoin/debug.log | grep 'Done loading' | wc -l`" = "x0" ]; do sleep 1; done
LD_PRELOAD=/usr/lib/jvm/java-6-openjdk/jre/lib/i386/jli/libjli.so java -Xmx2G -jar /mnt/test-scripts/BitcoinjBitcoindComparisonTool.jar /home/ubuntu/.bitcoin/comptool 1 $1
kill $BITCOIND_PID
sleep 15
if kill -9 $BITCOIND_PID ; then
	echo "Bitcoind didn't quit in time"
	exit 1
fi
rm -rf /home/ubuntu/.bitcoin/*
rm -f /home/ubuntu/.bitcoin/.lock

lcov -c -d `pwd` -b `pwd` -t BitcoinJBlockTest -o block_test.info
lcov -r baseline.info "/usr/include/*" -o baseline_filtered.info
lcov -r test_bitcoin.info "/usr/include/*" -o test_bitcoin_filtered.info
lcov -r block_test.info "/usr/include/*" -o block_test_filtered.info
lcov -a baseline_filtered.info -a test_bitcoin_filtered.info -o test_bitcoin_coverage.info
genhtml -s test_bitcoin_coverage.info -o test_bitcoin.coverage/
lcov -a baseline_filtered.info -a test_bitcoin_filtered.info -a block_test_filtered.info -o total_coverage.info | grep "\%" | awk '{ print substr($3,2,50) "/" $5 }' > ./coverage_percent.txt
genhtml -s total_coverage.info -o total.coverage/

LINES_COVERAGE=`cat ./coverage_percent.txt | head -n1`
FUNCTION_COVERAGE=`cat ./coverage_percent.txt | head -n2 | tail -n1`
LINES_TARGET=`cat /mnt/test-scripts/coverage_percent.txt | head -n1`
FUNCTION_TARGET=`cat /mnt/test-scripts/coverage_percent.txt | head -n2 | tail -n1`
EXIT_CODE=0
if [ "x"`echo "scale = 10; $LINES_COVERAGE < $LINES_TARGET || $FUNCTION_COVERAGE < $FUNCTION_TARGET" | bc` = "x1" ]; then
	EXIT_CODE=42
fi
cp ./coverage_percent.txt /mnt/test-scripts/coverage_percent.txt

git reset --hard
make -f makefile.unix clean
make -f makefile.unix -j6 test_bitcoin USE_UPNP=-
# Now run test_bitcoin normally
./test_bitcoin
make -f makefile.unix -j6 USE_UPNP=-
mkdir out && cp bitcoind test_bitcoin out/

cd ..

qmake bitcoin-qt.pro BITCOIN_QT_TEST=1 USE_UPNP=-
make -j6
./bitcoin-qt_test

mkdir out
mv bitcoin-qt_test out/
make clean

qmake bitcoin-qt.pro USE_UPNP=-
make -j6
mv bitcoin-qt out/
make clean

cd src
make -f makefile.unix clean

make -f makefile.linux-mingw -j6 DEPSDIR=/mnt/mingw test_bitcoin.exe
./test_bitcoin.exe
make -f makefile.linux-mingw -j6 DEPSDIR=/mnt/mingw USE_UPNP=0

cp bitcoind.exe test_bitcoin.exe out/

git apply ../contrib/test-patches/*.patch
make -f makefile.linux-mingw -j6 DEPSDIR=/mnt/mingw USE_UPNP=0
rm -rf /home/ubuntu/.bitcoin/*
rm -f /home/ubuntu/.bitcoin/.lock
./bitcoind.exe -connect=0.0.0.0 -datadir=/home/ubuntu/.bitcoin -rpcuser=user -rpcpassword=pass -listen -port=$1 -rpcport=$2 -keypool=3 -debug -logtimestamps &
BITCOIND_PID=$!
while [ "x`cat /home/ubuntu/.bitcoin/debug.log | grep 'Done loading' | wc -l`" = "x0" ]; do sleep 1; done
LD_PRELOAD=/usr/lib/jvm/java-6-openjdk/jre/lib/i386/jli/libjli.so java -Xmx2G -jar /mnt/test-scripts/BitcoinjBitcoindComparisonTool.jar /home/ubuntu/.bitcoin/comptool 0 $1
kill -9 $BITCOIND_PID
rm -rf /home/ubuntu/.bitcoin/*
rm -f /home/ubuntu/.bitcoin/.lock
git reset --hard

make -f makefile.linux-mingw clean
mv out/* ./
rm -r out
cd ..

/mnt/mingw/qt/bin/qmake -spec unsupported/win32-g++-cross BITCOIN_QT_TEST=1 PROTOBUF_LIB_PATH=/mnt/mingw/protobuf-2.5.0 PROTOBUF_INCLUDE_PATH=/mnt/mingw/protobuf-2.5.0/src PROTOC=/mnt/mingw/protobuf-2.5.0/protoc MINIUPNPC_LIB_PATH=/mnt/mingw/miniupnpc/ MINIUPNPC_INCLUDE_PATH=/mnt/mingw/ BDB_LIB_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BDB_INCLUDE_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BOOST_LIB_PATH=/mnt/mingw/boost_1_50_0/stage/lib BOOST_INCLUDE_PATH=/mnt/mingw/boost_1_50_0/ BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=/mnt/mingw/openssl-1.0.1c OPENSSL_INCLUDE_PATH=/mnt/mingw/openssl-1.0.1c/include/ QRENCODE_LIB_PATH=/mnt/mingw/qrencode-3.2.0/.libs QRENCODE_INCLUDE_PATH=/mnt/mingw/qrencode-3.2.0 USE_QRCODE=1 INCLUDEPATH=/mnt/mingw DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 QMAKE_MOC=/mnt/mingw/qt/bin/moc QMAKE_UIC=/mnt/mingw/qt/bin/uic
make -j6
./release/bitcoin-qt_test.exe
mv release/bitcoin-qt_test.exe out/

make clean
/mnt/mingw/qt/bin/qmake -spec unsupported/win32-g++-cross PROTOBUF_LIB_PATH=/mnt/mingw/protobuf-2.5.0 PROTOBUF_INCLUDE_PATH=/mnt/mingw/protobuf-2.5.0/src PROTOC=/mnt/mingw/protobuf-2.5.0/protoc MINIUPNPC_LIB_PATH=/mnt/mingw/miniupnpc/ MINIUPNPC_INCLUDE_PATH=/mnt/mingw/ BDB_LIB_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BDB_INCLUDE_PATH=/mnt/mingw/db-4.8.30.NC/build_unix/ BOOST_LIB_PATH=/mnt/mingw/boost_1_50_0/stage/lib BOOST_INCLUDE_PATH=/mnt/mingw/boost_1_50_0/ BOOST_LIB_SUFFIX=-mt-s BOOST_THREAD_LIB_SUFFIX=_win32-mt-s OPENSSL_LIB_PATH=/mnt/mingw/openssl-1.0.1c OPENSSL_INCLUDE_PATH=/mnt/mingw/openssl-1.0.1c/include/ QRENCODE_LIB_PATH=/mnt/mingw/qrencode-3.2.0/.libs QRENCODE_INCLUDE_PATH=/mnt/mingw/qrencode-3.2.0 USE_QRCODE=1 INCLUDEPATH=/mnt/mingw DEFINES=BOOST_THREAD_USE_LIB BITCOIN_NEED_QT_PLUGINS=1 QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 QMAKE_MOC=/mnt/mingw/qt/bin/moc QMAKE_UIC=/mnt/mingw/qt/bin/uic
make -j6
mv release/bitcoin-qt.exe out/
make clean

mv out/* ./
rm -r out

exit $EXIT_CODE
