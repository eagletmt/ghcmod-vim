function! s:normalize(qflist)
  for l:qf in a:qflist
    if has_key(l:qf, 'filename')
      let l:qf.filename = fnamemodify(l:qf.filename, ':.')
    endif
  endfor
  return a:qflist
endfunction

function! s:async(callback)
  let l:callback = { 'base': a:callback }
  function! l:callback.on_finish(qflist)
    let self.active = 0
    call self.base.on_finish(a:qflist)
  endfunction

  let l:callback.active = 1
  call ghcmod#async_make('check', expand('%:p'), l:callback)
  while l:callback.active
    sleep 100m
    " XXX:
    doautocmd CursorHold
  endwhile
endfunction

function! s:make_qf_pred(qf)
  let l:pred = deepcopy(a:qf)
  function! l:pred.call(qf)
    for l:key in ['lnum', 'col', 'type', 'filename']
      if self[l:key] != a:qf[l:key]
        return 0
      endif
    endfor
    return 1
  endfunction
  return l:pred
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_check()
  new test/data/with-cabal/src/Foo.hs
  let l:qflist = ghcmod#make('check', expand('%:p'))
  call s:normalize(l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 3, 'col': 1, 'type': 'W',
        \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
        \ }), l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 4, 'col': 1, 'type': 'W',
        \ 'filename': 'test/data/with-cabal/src/Foo.hs',
        \ }), l:qflist)
endfunction

function! s:unit.test_check_whitespace()
  new test/data/with\ whitespace/src/Foo.hs
  let l:qflist = ghcmod#make('check', expand('%:p'))
  call s:normalize(l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 3, 'col': 1, 'type': 'W',
        \ 'filename': 'test/data/with whitespace/src/Foo/Bar.hs',
        \ }), l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 4, 'col': 1, 'type': 'W',
        \ 'filename': 'test/data/with whitespace/src/Foo.hs',
        \ }), l:qflist)
endfunction

function! s:unit.test_check_compilation_error()
  new test/data/failure/Main.hs
  let l:qflist = ghcmod#make('check', expand('%:p'))
  call s:normalize(l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 3, 'col': 22, 'type': 'E',
        \ 'filename': 'test/data/failure/Main.hs',
        \ }), l:qflist)
endfunction

function! s:unit.test_check_async()
  new test/data/with-cabal/src/Foo.hs
  let l:callback = { 'assert': self.assert }
  function! l:callback.on_finish(qflist)
    call s:normalize(a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 3, 'col': 1, 'type': 'W',
          \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
          \ }), a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 4, 'col': 1, 'type': 'W',
          \ 'filename': 'test/data/with-cabal/src/Foo.hs',
          \ }), a:qflist)
  endfunction
  call s:async(l:callback)
endfunction

function! s:unit.test_check_async_compilation_error()
  new test/data/failure/Main.hs
  let l:callback = { 'assert': self.assert }
  function! l:callback.on_finish(qflist)
    call s:normalize(a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 3, 'col': 22, 'type': 'E',
          \ 'filename': 'test/data/failure/Main.hs',
          \ }), a:qflist)
  endfunction
  call s:async(l:callback)
endfunction

call s:unit.run()
