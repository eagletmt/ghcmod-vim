if exists('g:loaded_ghcmod') && g:loaded_ghcmod
  finish
endif
let g:loaded_ghcmod = 1

if !executable('ghc-mod')
  call ghcmod#print_error('ghcmod: ghc-mod is not executable!')
  finish
endif

let s:required_version = [1, 10, 6]
if !ghcmod#check_version(s:required_version)
  call ghcmod#print_error(printf('ghcmod: requires ghc-mod %s or higher', join(s:required_version, '.')))
  finish
endif

if !exists('g:ghcmod_type_highlight')
  let g:ghcmod_type_highlight = 'Search'
endif

command! -nargs=0 GhcModType echo ghcmod#type()[1]
command! -nargs=0 GhcModTypeClear call ghcmod#type_clear()
command! -nargs=0 GhcModCheck call s:check()
command! -nargs=0 GhcModLint call setqflist(ghcmod#make('lint')) | cwindow
command! -nargs=0 GhcModCheckAsync call ghcmod#async_make('check', '')
command! -nargs=0 GhcModLintAsync call ghcmod#async_make('lint', '')
command! -nargs=0 GhcModCheckAndLintAsync call s:check_and_lint_async()
if ghcmod#check_version([1, 10, 10])
  command! -nargs=0 GhcModExpand call setqflist(ghcmod#expand()) | cwindow
endif

function! s:check()
  let l:qflist = ghcmod#make('check')
  lcd `=expand('%:p:h')`
  call setqflist(l:qflist)
  lcd -
  cwindow
endfunction

function! s:check_and_lint_async()
  if !ghcmod#exist_session()
    call setqflist([])
    call ghcmod#async_make('check', 'a')
    call ghcmod#async_make('lint', 'a')
  endif
endfunction
