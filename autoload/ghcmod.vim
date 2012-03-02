let s:ghcmod_type = {
      \ 'ix': 0,
      \ 'types': [],
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
  call ghcmod#clear_highlight()
  let [l:line1, l:col1, l:line2, l:col2] = self.types[self.ix][0]
  let w:ghcmod_type_matchid = matchadd(a:group, '\%' . l:line1 . 'l\%' . l:col1 . 'c\_.*\%' . l:line2 . 'l\%' . l:col2 . 'c')
endfunction

function! s:on_enter()
  if exists('b:ghcmod_type')
    call b:ghcmod_type.highlight(g:ghcmod_type_highlight)
  endif
endfunction

function! s:on_leave()
  call ghcmod#clear_highlight()
endfunction

function! ghcmod#clear_highlight()
  if exists('w:ghcmod_type_matchid')
    call matchdelete(w:ghcmod_type_matchid)
    unlet w:ghcmod_type_matchid
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
  if l:file ==# ''
    call ghcmod#print_warning("current version of ghcmod.vim doesn't support running on an unnamed buffer.")
    return ['', '']
  endif
  let l:mod = ghcmod#detect_module()
  let l:cmd = ghcmod#build_command(['type', l:file, l:mod, l:line, l:col])
  let l:output = vimproc#system(l:cmd)
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

  call ghcmod#clear_highlight()
  let b:ghcmod_type = deepcopy(s:ghcmod_type)

  let b:ghcmod_type.types = l:types
  let l:ret = b:ghcmod_type.type()
  let [l:line1, l:col1, l:line2, l:col2] = l:ret[0]
  call b:ghcmod_type.highlight(g:ghcmod_type_highlight)

  augroup ghcmod-type-highlight
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call s:on_enter()
    autocmd WinEnter <buffer> call s:on_enter()
    autocmd BufLeave <buffer> call s:on_leave()
    autocmd WinLeave <buffer> call s:on_leave()
  augroup END

  return l:ret
endfunction

function! ghcmod#type_clear()
  if exists('b:ghcmod_type')
    call ghcmod#clear_highlight()
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

function! s:wait(proc)
  if has_key(a:proc, 'checkpid')
    return a:proc.checkpid()
  else
    " old vimproc
    if !exists('s:libcall')
      redir => l:output
      silent! scriptnames
      redir END
      for l:line in split(l:output, '\n')
        if l:line =~# '/vimproc/autoload/vimproc\.vim$'
          let s:libcall = function('<SNR>' . matchstr(l:line, '^\s*\zs\d\+') . '_libcall')
          break
        endif
      endfor
    endif
    return s:libcall('vp_waitpid', [a:proc.pid])
  endif
endfunction

function! ghcmod#parse_make(lines)
  " `ghc-mod check` and `ghc-mod lint` produces <NUL> characters but Vim cannot
  " treat them correctly.  Vim converts <NUL> characters to <NL> in readfile().
  " See also :help readfile() and :help NL-used-for-Nul.
  let l:qflist = []
  for l:output in a:lines
    let l:qf = {}
    let l:m = matchlist(l:output, '^\(\f\+\):\(\d\+\):\(\d\+\):\s*\(.*\)$')
    let [l:qf.filename, l:qf.lnum, l:qf.col, l:rest] = l:m[1 : 4]
    if l:rest =~# '^Warning:'
      let l:qf.type = 'W'
      let l:rest = matchstr(l:rest, '^Warning:\s*\zs.*$')
    elseif l:rest =~# '^Error:'
      let l:qf.type = 'E'
      let l:rest = matchstr(l:rest, '^Error:\s*\zs.*$')
    else
      let l:qf.type = 'E'
    endif
    let l:texts = split(l:rest, '\n')
    let l:qf.text = l:texts[0]
    call add(l:qflist, l:qf)

    for l:text in l:texts[1 :]
      call add(l:qflist, {'text': l:text})
    endfor
  endfor
  return l:qflist
endfunction

function! ghcmod#make(type)
  if &l:modified
    call ghcmod#print_warning('ghcmod#make: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#print_warning("ghcmod#make doesn't support running on an unnamed buffer.")
    return []
  endif

  let l:tmpfile = tempname()
  try
    let l:args = ghcmod#build_command([a:type, l:path])
    let l:proc = vimproc#plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
    let [l:cond, l:status] = s:wait(l:proc)
    let l:tries = 1
    while l:cond ==# 'run'
      if l:tries >= 50
        call l:proc.kill(15)  " SIGTERM
        call l:proc.waitpid()
        throw printf('ghcmod#make: `ghc-mod %s` takes too long time!', a:type)
      endif
      sleep 100m
      let [l:cond, l:status] = s:wait(l:proc)
      let l:tries += 1
    endwhile
  catch
    call ghcmod#print_error(printf('%s %s', v:throwpoint, v:exception))
  finally
    call delete(l:tmpfile)
  endtry
  return ghcmod#parse_make(readfile(l:tmpfile))
endfunction

let s:sessions = {}

function! ghcmod#exist_session()
  return !empty(s:sessions)
endfunction

function! ghcmod#async_make(type, action)
  if &l:modified
    call ghcmod#print_warning('ghcmod#async_make: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#print_warning("ghcmod#async_make doesn't support running on an unnamed buffer.")
    return
  endif
  if exists('s:proc')
    call ghcmod#print_error('ghcmod#async_make: already running!')
    return
  endif

  let l:tmpfile = tempname()
  try
    let l:args = ghcmod#build_command([a:type, l:path])
    let l:proc = vimproc#plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
    let l:key = reltimestr(reltime()) " this value should be unique
    if !exists('s:updatetime')
      let s:updatetime = &updatetime
    endif
    let s:sessions[l:key] = {
          \ 'proc': l:proc,
          \ 'tmpfile': l:tmpfile,
          \ 'action': a:action,
          \ }
    set updatetime=0
    augroup ghcmod-async-make
      execute 'autocmd CursorHold,CursorHoldI * call s:receive(' . string(l:key) . ')'
    augroup END
  catch
    if exists('l:proc')
      call l:proc.kill(15)
      call l:proc.waitpid()
    endif
    if exists('l:key') && has_key(s:sessions, l:key)
      call remove(s:sessions, l:key)
      if empty(s:sessions)
        augroup ghcmod-async-make
          autocmd!
        augroup END
        let &updatetime = s:updatetime
      endif
    endif
    call delete(l:tmpfile)
    call ghcmod#print_error(printf('%s %s', v:throwpoint, v:exception))
  endtry
endfunction

function! s:receive(key)
  if !has_key(s:sessions, a:key)
    return
  endif
  let l:session = s:sessions[a:key]
  let [l:cond, l:status] = s:wait(l:session.proc)
  if l:cond ==# 'run'
    return
  endif

  call remove(s:sessions, a:key)
  if empty(s:sessions)
    augroup ghcmod-async-make
      autocmd!
    augroup END
    let &updatetime = s:updatetime
  endif

  lcd `=expand('%:p:h')`
  call setqflist(ghcmod#parse_make(readfile(l:session.tmpfile)), l:session.action)
  lcd -
  call delete(l:session.tmpfile)
  cwindow
  if &l:buftype ==# 'quickfix'
    " go back to original window
    wincmd p
  endif
endfunction

function! s:wait(proc)
  if has_key(a:proc, 'checkpid')
    return a:proc.checkpid()
  else
    " old vimproc
    if !exists('s:libcall')
      redir => l:output
      silent! scriptnames
      redir END
      for l:line in split(l:output, '\n')
        if l:line =~# '/vimproc/autoload/vimproc\.vim$'
          let s:libcall = function('<SNR>' . matchstr(l:line, '^\s*\zs\d\+') . '_libcall')
          break
        endif
      endfor
    endif
    return s:libcall('vp_waitpid', [a:proc.pid])
  endif
endfunction
function! ghcmod#expand()
  if &l:modified
    call ghcmod#print_warning('ghcmod#expand: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#print_warning("ghcmod#expand doesn't support running on an unnamed buffer.")
    return []
  endif

  let l:qflist = []
  let l:cmd = ghcmod#build_command(['expand', l:path])
  for l:line in split(vimproc#system(l:cmd), '\n')
    let l:qf = {}
    " path:line:col1-col2: message
    " or path:line:col: message
    let l:m = matchlist(l:line, '^\s*\(\f\+\):\(\d\+\):\(\d\+\)\%(-\d\+\)\?\%(:\s*\(.*\)\)\?$')
    if !empty(l:m)
      let [l:qf.filename, l:qf.lnum, l:qf.col, l:qf.text] = l:m[1 : 4]
    else
      " path:(line1,col1):(line2,col2): message
      let l:m = matchlist(l:line, '^\s*\(\f\+\):(\(\d\+\),\(\d\+\))-(\d\+,\d\+)\%(:\s*\(.*\)\)\?$')
      if !empty(l:m)
        let [l:qf.filename, l:qf.lnum, l:qf.col, l:qf.text] = l:m[1 : 4]
      else
        " message
        let l:qf.text = substitute(l:line, '^\s\{2\}', '', '')
      endif
    endif
    call add(l:qflist, l:qf)
  endfor
  return l:qflist
endfunction

function! ghcmod#check_version(version)
  if !exists('s:ghc_mod_version')
    call vimproc#system('ghc-mod')
    let l:m = matchlist(vimproc#get_last_errmsg(), 'version \(\d\+\)\.\(\d\+\)\.\(\d\+\)')
    let s:ghc_mod_version = l:m[1 : 3]
    call map(s:ghc_mod_version, 'str2nr(v:val)')
  endif

  for l:i in range(0, 2)
    if a:version[l:i] > s:ghc_mod_version[l:i]
      return 0
    endif
  endfor
  return 1
endfunction

function! ghcmod#build_command(args)
  let l:cmd = ['ghc-mod']
  for l:opt in get(g:, 'ghcmod_ghc_options', [])
    call extend(l:cmd, ['-g', l:opt])
  endfor
  call extend(l:cmd, a:args)
  return l:cmd
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
