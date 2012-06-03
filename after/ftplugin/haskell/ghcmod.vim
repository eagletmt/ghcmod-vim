if exists('b:did_ftplugin_ghcmod') && b:did_ftplugin_ghcmod
  finish
endif
let b:did_ftplugin_ghcmod = 1

if !exists('s:has_ghc_mod')
  let s:has_ghc_mod = 0

  if !executable('ghc-mod')
    call ghcmod#print_error('ghcmod: ghc-mod is not executable!')
    finish
  endif

  let s:required_version = [1, 10, 11]
  if !ghcmod#check_version(s:required_version)
    call ghcmod#print_error(printf('ghcmod: requires ghc-mod %s or higher', join(s:required_version, '.')))
    finish
  endif

  let s:has_ghc_mod = 1
endif

if !s:has_ghc_mod
  finish
endif

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif

command! -buffer -nargs=0 GhcModType echo ghcmod#type()[1]
command! -buffer -nargs=0 GhcModTypeClear call ghcmod#type_clear()
command! -buffer -nargs=0 GhcModCheck call s:make('check')
command! -buffer -nargs=0 GhcModLint call s:make('lint')
command! -buffer -nargs=0 GhcModCheckAsync call ghcmod#async_make('check', '')
command! -buffer -nargs=0 GhcModLintAsync call ghcmod#async_make('lint', '')
command! -buffer -nargs=0 GhcModCheckAndLintAsync call s:check_and_lint_async()
command! -buffer -nargs=0 GhcModExpand call setqflist(ghcmod#expand()) | cwindow
let b:undo_ftplugin .= join(map([
      \ 'GhcModType',
      \ 'GhcModTypeClear',
      \ 'GhcModCheck',
      \ 'GhcModLint',
      \ 'GhcModCheckAsync',
      \ 'GhcModLintAsync',
      \ 'GhcModCheckAndLintAsync',
      \ 'GhcModExpand'
      \ ], '"delcommand " . v:val'), ' | ')
let b:undo_ftplugin .= ' | unlet b:did_ftplugin_ghcmod'

function! s:make(type)
  let l:qflist = ghcmod#make(a:type)
  call setqflist(l:qflist)
  cwindow
  if empty(l:qflist)
    echo printf('ghc-mod %s: No errors found', a:type)
  endif
endfunction

function! s:check_and_lint_async()
  if !ghcmod#async#exist_session()
    call setqflist([])
    call ghcmod#async_make('check', 'a')
    call ghcmod#async_make('lint', 'a')
  endif
endfunction
