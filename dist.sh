#!/bin/sh
exec vim -N -u NONE --cmd 'set runtimepath=.' -S dist.vim -c quit
