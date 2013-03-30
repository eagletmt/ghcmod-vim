set verbosefile=verbose.log

" Remove user's runtime path
set runtimepath-=~/.vim runtimepath-=~/.vim/after
let &runtimepath = join([
      \ &runtimepath,
      \ fnamemodify('vimproc', ':p'),
      \ fnamemodify('tinytest', ':p'),
      \ fnamemodify('.', ':p'),
      \ fnamemodify('./after', ':p'),
      \ ], ',')

syntax enable
filetype plugin indent on

let g:tinytest_default_config = { 'reporter': 'cli' }
