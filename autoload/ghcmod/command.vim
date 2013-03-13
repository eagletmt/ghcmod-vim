function! ghcmod#command#type(force) "{{{
  let l:line = line('.')
  let l:col = col('.')

  if exists('b:ghcmod_type')
    if b:ghcmod_type.spans(l:line, l:col)
      call b:ghcmod_type.incr_ix()
      call b:ghcmod_type.highlight()
      echo b:ghcmod_type.type()
      return
    endif
    call b:ghcmod_type.clear_highlight()
  endif

  if &l:modified
    let l:msg = 'ghcmod#type: the buffer has been modified but not written'
    if a:force
      call ghcmod#util#print_warning(l:msg)
    else
      call ghcmod#util#print_error(l:msg)
      return
    endif
  endif

  let l:file = expand('%:p')
  if l:file ==# ''
    call ghcmod#util#print_warning("current version of ghcmod.vim doesn't support running on an unnamed buffer.")
    return ['', '']
  endif

  let l:mod = ghcmod#detect_module()
  let l:types = ghcmod#type(l:line, l:col, l:file, l:mod)
  if empty(l:types)
    call ghcmod#util#print_error('ghcmod#command#type: Cannot guess type')
    return
  endif

  let b:ghcmod_type = ghcmod#type#new(l:types, ghcmod#highlight_group())
  call b:ghcmod_type.highlight()

  echo b:ghcmod_type.type()
endfunction "}}}

function! ghcmod#command#type_clear() "{{{
  if exists('b:ghcmod_type')
    call b:ghcmod_type.clear_highlight()
    unlet b:ghcmod_type
  endif
endfunction "}}}

function! ghcmod#command#type_insert(force) "{{{
  let l:fexp = ghcmod#getHaskellIdentifier()
  if empty(l:fexp)
    call ghcmod#util#print_error('Failed to determine identifier under cursor.')
    return 0
  endif

  if &l:modified
    let l:msg = 'ghcmod#type_insert: the buffer has been modified but not written'
    if a:force
      call ghcmod#util#print_warning(l:msg)
    else
      call ghcmod#util#print_error(l:msg)
      return
    endif
  endif

  let l:module = ghcmod#detect_module()
  let l:types = ghcmod#type(line('.'), col('.'), l:path, l:module)
  if empty(l:types) " Everything failed so let's just abort
    call ghcmod#util#print_error('ghcmod#command#type_insert: Cannot guess type')
    return
  endif
  let [l:locsym, l:type] = l:types[0]
  let l:signature = printf('%s :: %s', l:fexp, l:type)
  let [_, l:offset, _, _] = l:locsym

  if l:offset == 1 " We're doing top-level, let's try to use :info instead
    let l:info = ghcmod#info(l:fexp, l:path, l:module)
    if l:info !~# '^Dummy:0:0:Error' " Continue only if we don't find errors
      let l:info = substitute(l:info, '\n\|\t.*', "", "g") " Remove extra lines
      let l:info = substitute(l:info, '\s\+', " ", "g") " Compress whitespace
      let l:info = substitute(l:info, '\s\+$', "", "g") " Remove trailing whitespace
      let l:signature = l:info
    endif
  endif
  call append(line(".")-1, repeat(' ', l:offset-1) . l:signature)
endfunction "}}}

function! s:info(fexp) "{{{
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#command#info: the buffer has been modified but not written')
  endif

  let l:path = expand('%:p')
  if l:path ==# ''
    call ghcmod#util#print_error("current version of ghcmod.vim doesn't support running on an unnamed buffer.")
    return
  endif

  let l:fexp = a:fexp
  if empty(l:fexp)
    let l:fexp = ghcmod#getHaskellIdentifier()
  end
  return ghcmod#info(l:fexp, l:path, ghcmod#detect_module())
endfunction "}}}

function! ghcmod#command#info(fexp) "{{{
  let l:info = s:info(a:fexp)
  if !empty(l:info)
    echo l:info
  endif
endfunction "}}}

function! ghcmod#command#preview(fexp, ...) "{{{
  if a:0 == 0
    let l:size = get(g:, 'ghcmod_max_preview_size', 10)
  else
    let l:size = a:000[0]
  endif

  let l:info = s:info(a:fexp)

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
  let l:info = escape(l:info, '"|')
  silent 0put =l:info
  setlocal nomodifiable
  exec 'resize ' . min([line('$')+1, l:size])
  normal! gg
  wincmd p
endfunction "}}}

function! ghcmod#command#make(type) "{{{
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#make doesn't support running on an unnamed buffer.")
    return
  endif
  if &l:modified
    call ghcmod#util#print_warning('ghcmod#make: the buffer has been modified but not written')
  endif

  let l:qflist = ghcmod#make(a:type, l:path)
  call setqflist(l:qflist)
  cwindow
  if empty(l:qflist)
    echo printf('ghc-mod %s: No errors found', a:type)
  endif
endfunction "}}}

function! ghcmod#command#async_make(type, action) "{{{
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#async_make doesn't support running on an unnamed buffer.")
    return
  endif

  if &l:modified
    call ghcmod#util#print_warning('ghcmod#async_make: the buffer has been modified but not written')
  endif

  let l:callback = { 'action': a:action, 'type': a:type }
  function! l:callback.on_finish(qflist)
    call setqflist(a:qflist, self.action)
    cwindow
    if &l:buftype ==# 'quickfix'
      " go back to original window
      wincmd p
    endif
    if empty(a:qflist)
      echomsg printf('ghc-mod %s(async): No errors found', self.type)
    endif
  endfunction

  call ghcmod#async_make(a:type, l:path, l:callback)
endfunction "}}}

function! ghcmod#command#expand() "{{{
  let l:path = expand('%:p')
  if empty(l:path)
    call ghcmod#util#print_warning("ghcmod#expand doesn't support running on an unnamed buffer.")
    return
  endif

  if &l:modified
    call ghcmod#util#print_warning('ghcmod#expand: the buffer has been modified but not written')
  endif

  call setqflist(ghcmod#expand(l:path))
  cwindow
endfunction "}}}
