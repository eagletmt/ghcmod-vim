let s:ghcmod_type = {
      \ 'ix': 0,
      \ 'types': [],
      \ 'matchid': -1,
      \ }
function! s:ghcmod_type.spans(line, col)
  if empty(self.types)
    return 0
  endif
  let [l:line1, l:col1, l:line2, l:col2] = self.types[self.ix][0]
  return l:line1 <= a:line && a:line <= l:line2 && l:col1 <= a:col && a:col <= l:col2
endfunction

function! s:ghcmod_type.type()
  return self.types[self.ix]
endfunction

function! s:ghcmod_type.incr_ix()
  let self.ix = (self.ix + 1) % len(self.types)
endfunction

function! s:ghcmod_type.highlight(group)
  if empty(self.types)
    return
  endif
  if self.matchid != -1
    call self.clear_highlight()
  endif
  let [l:line1, l:col1, l:line2, l:col2] = self.types[self.ix][0]
  let self.matchid = matchadd(a:group, '\%' . l:line1 . 'l\%' . l:col1 . 'c\_.*\%' . l:line2 . 'l\%' . l:col2 . 'c')
endfunction

function! s:ghcmod_type.clear_highlight()
  if self.matchid != -1
    call matchdelete(self.matchid)
    let self.matchid = -1
  endif
endfunction

function! ghcmod#type()
  if &l:modified
    call ghcmod#print_warning('ghcmod#type: the buffer has been modified but not written')
  endif
  let l:line = line('.')
  let l:col = col('.')
  if exists('b:ghcmod_type') && b:ghcmod_type.spans(l:line, l:col)
    call b:ghcmod_type.incr_ix()
    call b:ghcmod_type.highlight(g:ghcmod_type_highlight)
    return b:ghcmod_type.type()
  endif

  let l:file = expand('%:p')
  let l:mod = ghcmod#detect_module()
  let l:output = vimproc#system(['ghc-mod', 'type', l:file, l:mod, l:line, l:col])
  let l:types = []
  for l:line in split(l:output, '\n')
    let l:m = matchlist(l:line, '\(\d\+\) \(\d\+\) \(\d\+\) \(\d\+\) "\([^"]\+\)"')
    call add(l:types, [l:m[1 : 4], l:m[5]])
  endfor
  let l:len = len(l:types)
  if l:len == 0
    call ghcmod#print_error('ghcmod#type: Cannot guess type')
    return
  endif

  if exists('b:ghcmod_type')
    call b:ghcmod_type.clear_highlight()
  endif
  let b:ghcmod_type = deepcopy(s:ghcmod_type)

  let b:ghcmod_type.types = l:types
  let l:ret = b:ghcmod_type.type()
  let [l:line1, l:col1, l:line2, l:col2] = l:ret[0]
  call b:ghcmod_type.highlight(g:ghcmod_type_highlight)
  return l:ret
endfunction

function! ghcmod#type_clear()
  if exists('b:ghcmod_type')
    call matchdelete(b:ghcmod_type.matchid)
    unlet b:ghcmod_type
  endif
endfunction

function! ghcmod#detect_module()
  let l:max_lineno = min([line('$'), 11])
  for l:lineno in range(1, l:max_lineno)
    let l:line = getline(l:lineno)
    let l:mod = matchstr(l:line, 'module \zs[A-Za-z0-9.]\+')
    if !empty(l:mod)
      return l:mod
    endif
    let l:lineno += 1
  endfor
  return 'Main'
endfunction

function! ghcmod#check_version(version)
  call vimproc#system('ghc-mod')
  let l:m = matchlist(vimproc#get_last_errmsg(), 'version \(\d\+\)\.\(\d\+\)\.\(\d\+\)')
  for l:i in range(0, 2)
    if a:version[l:i] > (l:m[l:i+1]+0)
      return 0
    endif
  endfor
  return 1
endfunction

function! ghcmod#print_error(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl None
endfunction

function! ghcmod#print_warning(msg)
  echohl WarningMsg
  echomsg a:msg
  echohl None
endfunction
