#!/bin/bash -ex

ghc_prefix=/mnt/drv1/ghc-root

pushd ..
ghc_rev=$(git rev-parse HEAD)
make -j40 distclean || true
git submodule update
ls
pwd
./boot
./configure --prefix=$ghc_prefix
make -j40
make -j40 install
popd

PATH=$ghc_prefix/bin:$PATH
LD_LIBRARY_PATH=$ghc_prefix/lib:$LD_LIBRARY_PATH

cabal sandbox delete || true
cabal sandbox init
cabal install accelerate-0.15.1.0/
cabal install --only-dependencies

res=0
timeout 120 cabal build || res=$?
if [ $res == 0 ]; then
	exit 0
else
	echo "Commit $ghc_rev failed with status $res"
	exit 1
fi
