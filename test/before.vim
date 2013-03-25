set verbosefile=verbose.log

" Remove user's runtime path
set runtimepath-=~/.vim runtimepath-=~/.vim/after
let &runtimepath = printf('%s,%s,%s,%s', &runtimepath, fnamemodify('vimproc', ':p'), fnamemodify('.', ':p'), fnamemodify('./after', ':p'))

syntax enable
filetype plugin indent on
