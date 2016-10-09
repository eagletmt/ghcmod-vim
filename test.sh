#!/bin/bash

shopt -s nullglob

run_tests() {
    for f in $1
    do
      testname=${f#test/test_}
      testname=${testname%.vim}
      echo "Running $testname"
      rm -f verbose.log
      if vim -e -N -u NONE $2 -S test/before.vim -S "$f" < /dev/null; then
        cat stdout.log
      else
        retval=$[retval + 1]
        cat stdout.log
        cat verbose.log
        echo
      fi
    done
}

retval=0

modonly_tests=(test/test_{expand,info,split,type,command_sig_codegen,command_split,command_type}.vim)

run_tests "test/test_*.vim"

# we cannot programmatically set this in our test case vimscripts as the
# variable is fixed once the script is loaded
echo "Setting ghcmod_should_use_ghc_modi=0"

TMPFILE=`mktemp /tmp/test.XXXXXX` || exit 1
echo "let g:ghcmod_should_use_ghc_modi=0" >> $TMPFILE

run_tests "${modonly_tests[*]}" "-S $TMPFILE"

rm -f $TMPFILE

exit $retval
