let &runtimepath = printf('%s,%s,%s', &runtimepath, fnamemodify('vimproc', ':p'), fnamemodify('.', ':p'))
set verbosefile=verbose.log
