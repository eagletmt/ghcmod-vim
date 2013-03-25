#!/bin/bash

shopt -s nullglob

rm -rf test/output
mkdir -p test/output

retval=0
for f in test/test_*.vim
do
  testname=${f#test/test_}
  testname=${testname%.vim}
  if vim -e -N -u NONE -S test/before.vim -S "$f" -c quit < /dev/null; then
    diff -u test/ok/$testname.ok test/output/$testname.out
    retval=$[retval + $?]
  else
    echo "$testname: vim exited with $?"
    retval=$[retval + 1]
  fi
done

exit $retval
