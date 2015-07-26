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

function! ghcmod#util#getcol() "{{{
  let l:line = line('.')
  let l:col = col('.')
  let l:str = getline(l:line)[:(l:col - 1)]
  let l:tabcnt = len(substitute(l:str, '[^\t]', '', 'g'))
  return l:col + 7 * l:tabcnt
endfunction "}}}

function! ghcmod#util#tocol(line, col) "{{{
  let l:str = getline(a:line)
  let l:len = len(l:str)
  let l:col = 0
  for l:i in range(1, l:len)
    let l:col += (l:str[l:i - 1] ==# "\t" ? 8 : 1)
    if l:col >= a:col
      return l:i
    endif
  endfor
  return l:len + 1
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
  if l:ghc_mod_version == [0, 0, 0]
    " 'version 0' should support all features.
    return 1
  end

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
    let l:ghcmod = vimproc#system(['ghc-mod','version'])
    let l:m = matchlist(l:ghcmod, 'version \(\d\+\)\.\(\d\+\)\.\(\d\+\)')
    if empty(l:m)
      if match(l:ghcmod, 'version 0 ') == -1
        call ghcmod#util#print_error(printf('ghcmod-vim: Cannot detect ghc-mod version from %s', l:ghcmod))
      else
        " 'version 0' means master
        " https://github.com/eagletmt/ghcmod-vim/issues/66
        let s:ghc_mod_version = [0, 0, 0]
      endif
    else
      let s:ghc_mod_version = l:m[1 : 3]
      call map(s:ghc_mod_version, 'str2nr(v:val)')
    endif
  endif
  return s:ghc_mod_version
endfunction "}}}

" vim: set ts=2 sw=2 et fdm=marker:
