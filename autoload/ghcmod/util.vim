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
  function! ghcmod#util#is_abspath(path)
    return a:path =~? '^[a-z]:[\/]'
  endfunction
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
