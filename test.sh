#!/bin/bash -ex

ghc_prefix=/mnt/drv1/ghc-root

PATH=/opt/ghc/7.8.3/bin:$PATH

pushd ..
ghc_rev=$(git rev-parse HEAD)
rm -Rf libraries/bootstrapping.conf
make -j40 distclean || true
git submodule update
ls
pwd
./boot
./configure --prefix=$ghc_prefix --with-ghc=/opt/ghc/7.8.3/bin/ghc
make -j40
make -j40 install
popd

PATH=$ghc_prefix/bin:$PATH
LD_LIBRARY_PATH=$ghc_prefix/lib:$LD_LIBRARY_PATH

cabal sandbox delete || true
cabal sandbox init
rm -fR dist accelerate/dist hashable-1.2.3.2/dist
cabal install accelerate/ hashable-1.2.3.2/ -j4 
cabal install -j4 --only-dependencies

res=0
timeout --signal=KILL --foreground 7m cabal install -j1 > $ghc_rev.log 2>&1 || res=$?
if [ $res == 124 ]; then
	# Timeout means we've failed, but we're doing an inverted bisection
	echo "$ghc_rev is bad"
	exit 0
elif [ $res == 0 ]; then
	echo "$ghc_rev finished compiling successfully"
	exit 1
else
	echo "Commit $ghc_rev failed with status $res"
	exit 1
fi
