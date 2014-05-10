function! ghcmod#highlight_group() "{{{
  return get(g:, 'ghcmod_type_highlight', 'Search')
endfunction "}}}

" Return the current haskell identifier
function! ghcmod#getHaskellIdentifier() "{{{
  let c = col ('.')-1
  let l = line('.')
  let ll = getline(l)
  let ll1 = strpart(ll,0,c)
  let ll1 = matchstr(ll1,"[a-zA-Z0-9_'.]*$")
  let ll2 = strpart(ll,c,strlen(ll)-c+1)
  let ll2 = matchstr(ll2,"^[a-zA-Z0-9_'.]*")
  return ll1.ll2
endfunction "}}}

function! ghcmod#info(fexp, path, module) "{{{
  let l:cmd = ghcmod#build_command(['info', a:path, a:module, a:fexp])
  let l:output = ghcmod#system(l:cmd)
  " Remove trailing newlines to prevent empty lines
  let l:output = substitute(l:output, '\n*$', '', '')
  " Remove 'Dummy:0:0:Error:' prefix.
  return substitute(l:output, '^Dummy:0:0:Error:', '', '')
endfunction "}}}

function! ghcmod#type(line, col, path, module) "{{{
  let l:cmd = ghcmod#build_command(['type', a:path, a:module, a:line, a:col])
  let l:output = ghcmod#system(l:cmd)
  let l:types = []
  for l:line in split(l:output, '\n')
    let l:m = matchlist(l:line, '\(\d\+\) \(\d\+\) \(\d\+\) \(\d\+\) "\([^"]\+\)"')
    if !empty(l:m)
      call add(l:types, [map(l:m[1 : 4], 'str2nr(v:val, 10)'), l:m[5]])
    endif
  endfor
  return l:types
endfunction "}}}

function! ghcmod#detect_module() "{{{
  let l:regex = '^\C>\=\s*module\s\+\zs[A-Za-z0-9.]\+'
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
endfunction "}}}

function! s:fix_qf_lnum_col(qf) "{{{
  " ghc-mod reports dummy error message with lnum=0 and col=0.
  " This is not suitable for Vim, so tweak them.
  for l:key in ['lnum', 'col']
    if get(a:qf, l:key, -1) == 0
      let a:qf[l:key] = 1
    endif
  endfor
endfunction "}}}

function! ghcmod#parse_make(lines, basedir) "{{{
  " `ghc-mod check` and `ghc-mod lint` produces <NUL> characters but Vim cannot
  " treat them correctly.  Vim converts <NUL> characters to <NL> in readfile().
  " See also :help readfile() and :help NL-used-for-Nul.
  let l:qflist = []
  for l:output in a:lines
    if empty(l:output)
      continue
    endif
    let l:qf = {}
    let l:m = matchlist(l:output, '^\(\(\f\| \)\+\):\(\d\+\):\(\d\+\):\s*\(.*\)$')
    if len(l:m) < 5
      let l:qf.bufnr = 0
      let l:qf.type = 'E'
      let l:qf.text = 'parse error in ghcmod! Could not parse the following ghc-mod output:' .  l:output
      call add(l:qflist, l:qf)
      break
    end
    let [l:qf.filename, _, l:qf.lnum, l:qf.col, l:rest] = l:m[1 : 5]
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
endfunction "}}}

function! s:build_make_command(type, path) "{{{
  let l:cmd = ghcmod#build_command([a:type])
  if a:type ==# 'lint'
    for l:hopt in get(g:, 'ghcmod_hlint_options', [])
      call extend(l:cmd, ['-h', l:hopt])
    endfor
  endif
  call add(l:cmd, a:path)
  return l:cmd
endfunction "}}}

function! ghcmod#make(type, path) "{{{
  let l:tmpfile = tempname()
  try
    let l:args = s:build_make_command(a:type, a:path)
    let l:proc = s:plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
    let [l:cond, l:status] = ghcmod#util#wait(l:proc)
    let l:tries = 1
    while l:cond ==# 'run'
      if l:tries >= 50
        call l:proc.kill(15)  " SIGTERM
        call l:proc.waitpid()
        throw printf('ghcmod#make: `ghc-mod %s` takes too long time!', a:type)
      endif
      sleep 100m
      let [l:cond, l:status] = ghcmod#util#wait(l:proc)
      let l:tries += 1
    endwhile
    return ghcmod#parse_make(readfile(l:tmpfile), b:ghcmod_basedir)
  catch
    call ghcmod#util#print_error(printf('%s %s', v:throwpoint, v:exception))
  finally
    call delete(l:tmpfile)
  endtry
endfunction "}}}

function! ghcmod#async_make(type, path, callback) "{{{
  let l:tmpfile = tempname()
  let l:args = s:build_make_command(a:type, a:path)
  let l:proc = s:plineopen2([{'args': l:args,  'fd': { 'stdin': '', 'stdout': l:tmpfile, 'stderr': '' }}])
  let l:obj = {
        \ 'proc': l:proc,
        \ 'tmpfile': l:tmpfile,
        \ 'callback': a:callback,
        \ 'type': a:type,
        \ 'basedir': ghcmod#basedir(),
        \ }
  function! l:obj.on_finish(cond, status)
    let l:qflist = ghcmod#parse_make(readfile(self.tmpfile), self.basedir)
    call delete(self.tmpfile)
    call self.callback.on_finish(l:qflist)
  endfunction

  if !ghcmod#async#register(l:obj)
    call l:proc.kill(15)
    call l:proc.waitpid()
    call delete(l:tmpfile)
  endif
endfunction "}}}

function! ghcmod#expand(path) "{{{
  let l:dir = fnamemodify(a:path, ':h')

  let l:qflist = []
  let l:cmd = ghcmod#build_command(['expand', "-b '\n'", a:path])
  for l:line in split(ghcmod#system(l:cmd), '\n')
    " path:line:col1-col2: message
    " or path:line:col: message
    let l:m = matchlist(l:line, '^\s*\(\(\f\| \)\+\):\(\d\+\):\(\d\+\)\%(-\(\d\+\)\)\?\%(:\s*\(.*\)\)\?$')
    if !empty(l:m)
      let l:qf = {}
      let [l:qf.filename, _, l:qf.lnum, l:qf.col, l:col2, l:qf.text] = l:m[1 : 6]
      call add(l:qflist, l:qf)
      if !empty(l:col2)
        let l:qf2 = deepcopy(l:qf)
        let l:qf2.col = l:col2
        let l:qf2.text = 'Splicing end here'
        call add(l:qflist, l:qf2)
      endif
    else
      " path:(line1,col1)-(line2,col2): message
      let l:m = matchlist(l:line, '^\s*\(\(\f\| \)\+\):(\(\d\+\),\(\d\+\))-(\(\d\+\),\(\d\+\))\%(:\s*\(.*\)\)\?$')
      if !empty(l:m)
        let [l:filename, _, l:lnum1, l:col1, l:lnum2, l:col2, l:text] = l:m[1 : 7]
        call add(l:qflist, { 'filename': l:filename, 'lnum': l:lnum1, 'col': l:col1, 'text': l:text })
        call add(l:qflist, { 'filename': l:filename, 'lnum': l:lnum2, 'col': l:col2, 'text': 'Splicing end here' })
      else
        " message
        let l:text = substitute(l:line, '^\s\{2\}', '', '')
        call add(l:qflist, { 'text': l:text })
      endif
    endif
  endfor

  for l:qf in l:qflist
    if has_key(l:qf, 'filename')
      let l:qf.filename = ghcmod#util#join_path(l:dir, l:qf.filename)
    endif
    if has_key(l:qf, 'lnum')
      let l:qf.lnum = str2nr(l:qf.lnum)
      let l:qf.col = str2nr(l:qf.col)
    endif
    call s:fix_qf_lnum_col(l:qf)
  endfor
  return l:qflist
endfunction "}}}

function! ghcmod#add_autogen_dir(path, cmd) "{{{
  " detect autogen directory
  let l:autogen_dir = a:path . '/autogen'
  if isdirectory(l:autogen_dir)
    call extend(a:cmd, ['-g', '-i' . l:autogen_dir, '-g', '-I' . l:autogen_dir])
    let l:macros_path = l:autogen_dir . '/cabal_macros.h'
    if filereadable(l:macros_path)
      call extend(a:cmd, ['-g', '-optP-include', '-g', '-optP' . l:macros_path])
    endif
  endif
endfunction "}}}

function! ghcmod#build_command(args) "{{{
  let l:cmd = ['ghc-mod']

  let l:dist_top  = s:find_basedir() . '/dist'
  let l:sandboxes = split(glob(l:dist_top . '/dist-*', 1), '\n')
  for l:dist_dir in [l:dist_top] + l:sandboxes
    let l:build_dir = l:dist_dir . '/build'
    if isdirectory(l:build_dir)
      call ghcmod#add_autogen_dir(l:build_dir, l:cmd)

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
  endfor

  if exists('b:ghcmod_ghc_options')
    let l:opts = b:ghcmod_ghc_options
  else
    let l:opts = get(g:, 'ghcmod_ghc_options', [])
  endif
  for l:opt in l:opts
    call extend(l:cmd, ['-g', l:opt])
  endfor
  call extend(l:cmd, a:args)
  return l:cmd
endfunction "}}}

function! ghcmod#system(...) "{{{
  lcd `=ghcmod#basedir()`
  let l:ret = call('vimproc#system', a:000)
  lcd -
  return l:ret
endfunction "}}}

function! s:plineopen2(...) "{{{
  lcd `=ghcmod#basedir()`
  let l:ret = call('vimproc#plineopen2', a:000)
  lcd -
  return l:ret
endfunction "}}}

function! ghcmod#basedir() "{{{
  let l:use_basedir = get(g:, 'ghcmod_use_basedir', '')
  if empty(l:use_basedir)
    return s:find_basedir()
  else
    return l:use_basedir
  endif
endfunction "}}}

function! s:find_basedir() "{{{
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
endfunction "}}}

function! ghcmod#version() "{{{
  return [1, 2, 0]
endfunction "}}}

" vim: set ts=2 sw=2 et fdm=marker:
