#!/bin/bash

shopt -s nullglob

retval=0
for f in test/test_*.vim
do
  testname=${f#test/test_}
  testname=${testname%.vim}
  echo "Running $testname"
  rm -f verbose.log
  if vim -e -N -u NONE -S test/before.vim -S "$f" < /dev/null; then
    cat stdout.log
  else
    retval=$[retval + 1]
    cat stdout.log
    cat verbose.log
    echo
  fi
done

exit $retval
