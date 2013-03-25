#!/bin/sh
set -e

if [ -d vimproc ]; then
  cd vimproc
  git pull origin master
else
  git clone git://github.com/Shougo/vimproc
  cd vimproc
fi

make -f make_unix.mak

cabal install ghc-mod
