#!/bin/sh
set -e

if [ -d tinytest ]; then
  (cd tinytest; git pull origin master)
else
  git clone https://github.com/eagletmt/tinytest.git
fi

if [ -d vimproc ]; then
  cd vimproc
  git pull origin master
else
  git clone https://github.com/Shougo/vimproc.git
  cd vimproc
fi
make -f make_unix.mak

cabal update
cabal install ghc-mod
