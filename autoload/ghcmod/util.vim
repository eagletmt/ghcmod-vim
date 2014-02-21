function! ghcmod#util#print_warning(msg) "{{{
  echohl WarningMsg
  echomsg a:msg
  echohl None
endfunction "}}}

function! ghcmod#util#print_error(msg) "{{{
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction "}}}

if vimproc#util#is_windows() " s:is_abspath {{{
  if v:version > 704 || (v:version == 704 && has('patch001'))
    function! ghcmod#util#is_abspath(path)
      return a:path =~? '^[a-z]:[\/]'
    endfunction
  else
    " NFA regexp engine had a bug and fixed in 7.4.001.
    " http://code.google.com/p/vim/source/detail?r=3e9107b86b68d83bfa94e43afffbf17623afe55e
    function! ghcmod#util#is_abspath(path)
      return a:path =~# '^[A-Za-z]:[\/]'
    endfunction
  endif
else
  function! ghcmod#util#is_abspath(path)
    return a:path[0] ==# '/'
  endfunction
endif "}}}

if v:version > 703 || (v:version == 703 && has('patch465')) "{{{
  function! ghcmod#util#globlist(pat)
    return glob(a:pat, 0, 1)
  endfunction
else
  function! ghcmod#util#globlist(pat)
    return split(glob(a:pat, 0), '\n')
  endfunction
endif "}}}

function! ghcmod#util#join_path(dir, path) "{{{
  if ghcmod#util#is_abspath(a:path)
    return a:path
  else
    return a:dir . '/' . a:path
  endif
endfunction "}}}

function! ghcmod#util#wait(proc) "{{{
  if has_key(a:proc, 'checkpid')
    return a:proc.checkpid()
  else
    " old vimproc
    if !exists('s:libcall')
      redir => l:output
      silent! scriptnames
      redir END
      for l:line in split(l:output, '\n')
        if l:line =~# 'autoload/vimproc\.vim$'
          let s:libcall = function('<SNR>' . matchstr(l:line, '^\s*\zs\d\+') . '_libcall')
          break
        endif
      endfor
    endif
    return s:libcall('vp_waitpid', [a:proc.pid])
  endif
endfunction "}}}

function! ghcmod#util#check_version(version) "{{{
  let l:ghc_mod_version = ghcmod#util#ghc_mod_version()
  for l:i in range(0, 2)
    if a:version[l:i] > l:ghc_mod_version[l:i]
      return 0
    elseif a:version[l:i] < l:ghc_mod_version[l:i]
      return 1
    endif
  endfor
  return 1
endfunction "}}}

function! ghcmod#util#ghc_mod_version() "{{{
  if !exists('s:ghc_mod_version')
    call vimproc#system(['ghc-mod'])
    let l:m = matchlist(vimproc#get_last_errmsg(), 'version \(\d\+\)\.\(\d\+\)\.\(\d\+\)')
    let s:ghc_mod_version = l:m[1 : 3]
    call map(s:ghc_mod_version, 'str2nr(v:val)')
  endif
  return s:ghc_mod_version
endfunction "}}}

" vim: set ts=2 sw=2 et fdm=marker:
