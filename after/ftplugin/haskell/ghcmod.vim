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

if !exists('g:ghcmod_max_preview_size')
  let g:ghcmod_max_preview_size = 10
endif

command! -buffer -nargs=0 -bang GhcModType call ghcmod#command#type(<bang>0)
command! -buffer -nargs=0 -bang GhcModTypeInsert call ghcmod#command#type_insert(<bang>0)
command! -buffer -nargs=? GhcModInfo call ghcmod#command#info(<q-args>)
command! -buffer -nargs=0 GhcModTypeClear call ghcmod#command#type_clear()
command! -buffer -nargs=? GhcModInfoPreview call ghcmod#preview(s:info(<q-args>), g:ghcmod_max_preview_size)
command! -buffer -nargs=0 GhcModCheck call ghcmod#command#make('check')
command! -buffer -nargs=0 GhcModLint call ghcmod#command#make('lint')
command! -buffer -nargs=0 GhcModCheckAsync call ghcmod#command#async_make('check', '')
command! -buffer -nargs=0 GhcModLintAsync call ghcmod#command#async_make('lint', '')
command! -buffer -nargs=0 GhcModCheckAndLintAsync call s:check_and_lint_async()
command! -buffer -nargs=0 GhcModExpand call ghcmod#command#expand()
let b:undo_ftplugin .= join(map([
      \ 'GhcModType',
      \ 'GhcModTypeInsert',
      \ 'GhcModInfo',
      \ 'GhcModInfoPreview',
      \ 'GhcModTypeClear',
      \ 'GhcModCheck',
      \ 'GhcModLint',
      \ 'GhcModCheckAsync',
      \ 'GhcModLintAsync',
      \ 'GhcModCheckAndLintAsync',
      \ 'GhcModExpand'
      \ ], '"delcommand " . v:val'), ' | ')
let b:undo_ftplugin .= ' | unlet b:did_ftplugin_ghcmod'

" Ensure syntax highlighting for ghcmod#detect_module()
syntax sync fromstart

function! s:echo(msg)
  if !empty(a:msg)
    echo a:msg
  endif
endfunction

function! s:check_and_lint_async()
  if !ghcmod#async#exist_session()
    call setqflist([])
    call ghcmod#command#async_make('check', 'a')
    call ghcmod#command#async_make('lint', 'a')
  endif
endfunction
