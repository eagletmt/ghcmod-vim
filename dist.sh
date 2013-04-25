#!/bin/sh
exec vim -e -N -u NONE --cmd 'set runtimepath=.,~/.vim/bundle/vimproc' -S dist.vim -c quit < /dev/null
