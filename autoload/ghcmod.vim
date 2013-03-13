function! ghcmod#highlight_group() "{{{
  return get(g:, 'ghcmod_type_highlight', 'Search')
endfunction "}}}

" Return the current haskell identifier
function! ghcmod#getHaskellIdentifier()"{{{
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,"[a-zA-Z0-9_'.]*$")
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = matchstr(ll2,"^[a-zA-Z0-9_'.]*")
  return ll1.ll2
endfunction"}}}

function! ghcmod#info(fexp)"{{{
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#info: the buffer has been modified but not written')
  endif
  let l:file = expand('%:p')
  if l:file ==# ''
    call ghcmod#util#print_warning("current version of ghcmod.vim doesn't support running on an unnamed buffer.")
    return ''
  endif
  let l:mod = ghcmod#detect_module()
  let l:cmd = ghcmod#build_command(['info', l:file, l:mod, a:fexp])
  let l:output = s:system(l:cmd)
  " Remove trailing newlines to prevent empty lines from being echoed
  let l:output = substitute(l:output, '\n*$', '', '')

  return l:output
endfunction"}}}

function! ghcmod#type(line, col, path, module) "{{{
  let l:cmd = ghcmod#build_command(['type', a:path, a:module, a:line, a:col])
  let l:output = s:system(l:cmd)
  let l:types = []
  for l:line in split(l:output, '\n')
    let l:m = matchlist(l:line, '\(\d\+\) \(\d\+\) \(\d\+\) \(\d\+\) "\([^"]\+\)"')
    if !empty(l:m)
      call add(l:types, [l:m[1 : 4], l:m[5]])
    endif
  endfor
  return l:types
endfunction "}}}

function! ghcmod#detect_module()"{{{
  let l:regex = '^\C\s*module\s\+\zs[A-Za-z0-9.]\+'
  for l:lineno in range(1, line('$'))
    let l:line = getline(l:lineno)
    let l:pos = match(l:line, l:regex)
    if l:pos != -1
      let l:synname = synIDattr(synID(l:lineno, l:pos+1, 0), 'name')
      if l:synname !~# 'Comment'
        return matchstr(l:line, l:regex)
      endif
    endif
    let l:lineno += 1
  endfor
  return 'Main'
endfunction"}}}

function! s:fix_qf_lnum_col(qf)"{{{
  " ghc-mod reports dummy error message with lnum=0 and col=0.
  " This is not suitable for Vim, so tweak them.
  for l:key in ['lnum', 'col']
    if get(a:qf, l:key, -1) == 0
      let a:qf[l:key] = 1
    endif
  endfor
endfunction"}}}

function! ghcmod#parse_make(lines, basedir)"{{{
  " `ghc-mod check` and `ghc-mod lint` produces <NUL> characters but Vim cannot
  " treat them correctly.  Vim converts <NUL> characters to <NL> in readfile().
  " See also :help readfile() and :help NL-used-for-Nul.
  let l:qflist = []
  for l:output in a:lines
    let l:qf = {}
    let l:m = matchlist(l:output, '^\(\f\+\):\(\d\+\):\(\d\+\):\s*\(.*\)$')
    if len(l:m) < 4
      let l:qf.bufnr = 0
      let l:qf.type = 'E'
      let l:qf.text = 'parse error in ghcmod! Could not parse the following ghc-mod output:' .  l:output
      call add(l:qflist, l:qf)
      break
    end
    let [l:qf.filename, l:qf.lnum, l:qf.col, l:rest] = l:m[1 : 4]
    let l:qf.filename = ghcmod#util#join_path(a:basedir, l:qf.filename)
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
    if len(l:texts) > 0
      let l:qf.text = l:texts[0]
      call add(l:qflist, l:qf)
      for l:text in l:texts[1 :]
        call add(l:qflist, {'text': l:text})
      endfor
    else
      let l:qf.type = 'E'
      call s:fix_qf_lnum_col(l:qf)
      let l:qf.text = 'parse error in ghcmod! Could not parse the following ghc-mod output:'
      call add(l:qflist, l:qf)
      for l:text in a:lines
        call add(l:qflist, {'text': l:text})
      endfor
      break
    endif
  endfor
  return l:qflist
endfunction"}}}

function! s:build_make_command(type, path)"{{{
  let l:cmd = ghcmod#build_command([a:type])
  if a:type ==# 'lint'
    for l:hopt in get(g:, 'ghcmod_hlint_options', [])
      call extend(l:cmd, ['-h', l:hopt])
    endfor
  endif
  call add(l:cmd, a:path)
  return l:cmd
endfunction"}}}

function! ghcmod#make(type)"{{{
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#make: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#make doesn't support running on an unnamed buffer.")
    return []
  endif
  let l:dir = fnamemodify(l:path, ':h')

  let l:tmpfile = tempname()
  try
    let l:args = s:build_make_command(a:type, l:path)
    let l:proc = s:plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
    let [l:cond, l:status] = ghcmod#wait(l:proc)
    let l:tries = 1
    while l:cond ==# 'run'
      if l:tries >= 50
        call l:proc.kill(15)  " SIGTERM
        call l:proc.waitpid()
        throw printf('ghcmod#make: `ghc-mod %s` takes too long time!', a:type)
      endif
      sleep 100m
      let [l:cond, l:status] = ghcmod#wait(l:proc)
      let l:tries += 1
    endwhile
    return ghcmod#parse_make(readfile(l:tmpfile), b:ghcmod_basedir)
  catch
    call ghcmod#util#print_error(printf('%s %s', v:throwpoint, v:exception))
  finally
    call delete(l:tmpfile)
  endtry
endfunction"}}}

function! s:SID_PREFIX()"{{{
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction"}}}

function! s:funcref(funcname)"{{{
  return function(s:SID_PREFIX() . a:funcname)
endfunction"}}}

function! ghcmod#async_make(type, action)"{{{
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#async_make: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#async_make doesn't support running on an unnamed buffer.")
    return
  endif

  let l:tmpfile = tempname()
  let l:args = s:build_make_command(a:type, l:path)
  let l:proc = s:plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
  let l:obj = {
        \ 'proc': l:proc,
        \ 'tmpfile': l:tmpfile,
        \ 'action': a:action,
        \ 'type': a:type,
        \ 'basedir': b:ghcmod_basedir,
        \ 'on_finish': s:funcref('on_finish'),
        \ }
  if !ghcmod#async#register(l:obj)
    call l:proc.kill(15)
    call l:proc.waitpid()
    call delete(l:tmpfile)
  endif
endfunction"}}}

function! s:on_finish(cond, status) dict"{{{
  let l:qflist = ghcmod#parse_make(readfile(self.tmpfile), self.basedir)
  call setqflist(l:qflist, self.action)
  call delete(self.tmpfile)
  cwindow
  if &l:buftype ==# 'quickfix'
    " go back to original window
    wincmd p
  endif
  if empty(l:qflist)
    echomsg printf('ghc-mod %s(async): No errors found', self.type)
  endif
endfunction"}}}

function! ghcmod#wait(proc)"{{{
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
endfunction"}}}

function! ghcmod#expand()"{{{
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#expand: the buffer has been modified but not written')
  endif
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#expand doesn't support running on an unnamed buffer.")
    return []
  endif
  let l:dir = fnamemodify(l:path, ':h')

  let l:qflist = []
  let l:cmd = ghcmod#build_command(['expand', l:path])
  for l:line in split(s:system(l:cmd), '\n')
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
    if has_key(l:qf, 'filename')
      let l:qf.filename = ghcmod#util#join_path(l:dir, l:qf.filename)
    endif
    call s:fix_qf_lnum_col(l:qf)
    call add(l:qflist, l:qf)
  endfor
  return l:qflist
endfunction"}}}

function! ghcmod#check_version(version)"{{{
  if !exists('s:ghc_mod_version')
    call s:system('ghc-mod')
    let l:m = matchlist(vimproc#get_last_errmsg(), 'version \(\d\+\)\.\(\d\+\)\.\(\d\+\)')
    let s:ghc_mod_version = l:m[1 : 3]
    call map(s:ghc_mod_version, 'str2nr(v:val)')
  endif

  for l:i in range(0, 2)
    if a:version[l:i] > s:ghc_mod_version[l:i]
      return 0
    elseif a:version[l:i] < s:ghc_mod_version[l:i]
      return 1
    endif
  endfor
  return 1
endfunction"}}}

function! ghcmod#build_command(args)"{{{
  let l:cmd = ['ghc-mod']

  let l:build_dir = s:find_basedir() . '/dist/build'
  if isdirectory(l:build_dir)
    " detect autogen directory
    let l:autogen_dir = l:build_dir . '/autogen'
    if isdirectory(l:autogen_dir)
      call extend(l:cmd, ['-g', '-i' . l:autogen_dir, '-g', '-I' . l:autogen_dir])
      let l:macros_path = l:autogen_dir . '/cabal_macros.h'
      if filereadable(l:macros_path)
        call extend(l:cmd, ['-g', '-optP-include', '-g', '-optP' . l:macros_path])
      endif
    endif

    let l:tmps = ghcmod#util#globlist(l:build_dir . '/*/*-tmp')
    if !empty(l:tmps)
      " add *-tmp directory to include path for executable project
      for l:tmp in l:tmps
        call extend(l:cmd, ['-g', '-i' . l:tmp, '-g', '-I' . l:tmp])
      endfor
    else
      " add build directory to include path for library project
      call extend(l:cmd, ['-g', '-i' . l:build_dir, '-g', '-I' . l:build_dir])
    endif
  endif

  if exists('b:ghcmod_ghc_options')
    let l:opts = b:ghcmod_ghc_options
  else
    let l:opts = []
  endif
  for l:opt in l:opts
    call extend(l:cmd, ['-g', l:opt])
  endfor
  call extend(l:cmd, a:args)
  return l:cmd
endfunction"}}}

function! s:system(...)"{{{
  lcd `=ghcmod#basedir()`
  let l:ret = call('vimproc#system', a:000)
  lcd -
  return l:ret
endfunction"}}}

function! s:plineopen2(...)"{{{
  lcd `=ghcmod#basedir()`
  let l:ret = call('vimproc#plineopen2', a:000)
  lcd -
  return l:ret
endfunction"}}}

function! ghcmod#basedir()"{{{
  let l:use_basedir = get(g:, 'ghcmod_use_basedir', '')
  if empty(l:use_basedir)
    return s:find_basedir()
  else
    return l:use_basedir
  endif
endfunction"}}}

function! s:find_basedir()"{{{
  " search Cabal file
  if !exists('b:ghcmod_basedir')
    let l:ghcmod_basedir = expand('%:p:h')
    let l:dir = l:ghcmod_basedir
    for _ in range(6)
      if !empty(glob(l:dir . '/*.cabal', 0))
        let l:ghcmod_basedir = l:dir
        break
      endif
      let l:dir = fnamemodify(l:dir, ':h')
    endfor
    let b:ghcmod_basedir = l:ghcmod_basedir
  endif
  return b:ghcmod_basedir
endfunction"}}}

function! ghcmod#version()"{{{
  return [0, 4, 0]
endfunction"}}}

function! ghcmod#preview(str, size) "{{{
  silent! wincmd P
  if !(&previewwindow && expand("%:t") == "GHC-mod")
      pclose
      pedit GHC-mod
      silent! wincmd P
  endif
  setlocal modifiable
  setlocal buftype=nofile
  " make sure buffer is deleted when view is closed
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nonumber
  setlocal statusline=%F
  setlocal nofoldenable
  setlocal filetype=haskell
  setlocal nolist
  let l:str = escape(a:str, '"|')
  silent 0put =l:str
  setlocal nomodifiable
  exec 'resize ' . min([line('$')+1, a:size])
  normal gg
  wincmd p
  return
endfunction "}}}

" vim: set ts=2 sw=2 et fdm=marker:
