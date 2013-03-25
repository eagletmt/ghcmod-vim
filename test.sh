#!/bin/bash

shopt -s nullglob

retval=0
for f in test/test_*.vim
do
  testname=${f#test/test_}
  testname=${testname%.vim}
  vim -e -N -u NONE -S test/before.vim -S "$f" -c quit
  diff -u test/ok/$testname.ok test/output/$testname.out
  retval=$[retval + $?]
done

exit $retval
