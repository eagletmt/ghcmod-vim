function! ghcmod#type()
  if &l:modified
    call ghcmod#print_warning('ghcmod#type: the buffer has been modified but not written')
  endif
  let l:line = line('.')
  let l:col = col('.')
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
    if b:ghcmod_type.ix < l:len && b:ghcmod_type.span == l:types[b:ghcmod_type.ix][0]
      let b:ghcmod_type.ix = (b:ghcmod_type.ix + 1) % l:len
    else
      let b:ghcmod_type.ix = 0
    endif
    call matchdelete(b:ghcmod_type.matchid)
  else
    let b:ghcmod_type = {}
    let b:ghcmod_type.ix = 0
  endif

  let l:ret = l:types[b:ghcmod_type.ix]
  let [b:ghcmod_type.span, l:type] = l:ret
  let [l:line1, l:col1, l:line2, l:col2] = b:ghcmod_type.span
  let b:ghcmod_type.matchid = matchadd(g:ghcmod_type_highlight, '\%' . l:line1 . 'l\%' . l:col1 . 'c\_.*\%' . l:line2 . 'l\%' . l:col2 . 'c')
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
