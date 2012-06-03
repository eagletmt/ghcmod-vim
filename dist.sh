#!/bin/sh
exec vim -N -u NONE --cmd 'set runtimepath=.,~/.vim/bundle/vimproc' -S dist.vim -c quit
