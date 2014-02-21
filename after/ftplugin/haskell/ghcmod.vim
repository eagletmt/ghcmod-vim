if exists('b:did_ftplugin_ghcmod') && b:did_ftplugin_ghcmod
  finish
endif
let b:did_ftplugin_ghcmod = 1

if !exists('s:has_vimproc')
  try
    call vimproc#version()
    let s:has_vimproc = 1
  catch /^Vim\%((\a\+)\)\=:E117/
    let s:has_vimproc = 0
  endtry
endif

if !s:has_vimproc
  echohl ErrorMsg
  echomsg 'ghcmod: vimproc.vim is not installed!'
  echohl None
  finish
endif

if !exists('s:has_ghc_mod')
  let s:has_ghc_mod = 0

  if !executable('ghc-mod')
    call ghcmod#util#print_error('ghcmod: ghc-mod is not executable!')
    finish
  endif

  let s:required_version = [2, 1, 2]
  if !ghcmod#util#check_version(s:required_version)
    call ghcmod#util#print_error(printf('ghcmod: requires ghc-mod %s or higher', join(s:required_version, '.')))
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

command! -buffer -nargs=0 -bang GhcModType call ghcmod#command#type(<bang>0)
command! -buffer -nargs=0 -bang GhcModTypeInsert call ghcmod#command#type_insert(<bang>0)
command! -buffer -nargs=? -bang GhcModInfo call ghcmod#command#info(<q-args>, <bang>0)
command! -buffer -nargs=0 GhcModTypeClear call ghcmod#command#type_clear()
command! -buffer -nargs=? -bang GhcModInfoPreview call ghcmod#command#info_preview(<q-args>, <bang>0)
command! -buffer -nargs=0 -bang GhcModCheck call ghcmod#command#make('check', <bang>0)
command! -buffer -nargs=0 -bang GhcModLint call ghcmod#command#make('lint', <bang>0)
command! -buffer -nargs=0 -bang GhcModCheckAsync call ghcmod#command#async_make('check', <bang>0)
command! -buffer -nargs=0 -bang GhcModLintAsync call ghcmod#command#async_make('lint', <bang>0)
command! -buffer -nargs=0 -bang GhcModCheckAndLintAsync call ghcmod#command#check_and_lint_async(<bang>0)
command! -buffer -nargs=0 -bang GhcModExpand call ghcmod#command#expand(<bang>0)
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

" vim: set ts=2 sw=2 et fdm=marker:
