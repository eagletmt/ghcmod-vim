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
  call ghcmod#async_make('lint', expand('%:p'), l:callback)
  while l:callback.active
    sleep 100m
    " XXX:
    doautocmd CursorHold
  endwhile
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:make_qf_pred(qf)
  let l:pred = deepcopy(a:qf)
  let l:pred.__qf = a:qf
  function! l:pred.call(qf)
    if !has_key(a:qf, 'type')
      return 0
    endif
    for l:key in keys(self.__qf)
      if self[l:key] != a:qf[l:key]
        return 0
      endif
    endfor
    return 1
  endfunction
  return l:pred
endfunction

function! s:unit.test_lint()
  edit test/data/with-cabal/src/Foo/Bar.hs
  let l:qflist = s:normalize(ghcmod#make('lint', expand('%:p')))
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 5,
        \ 'col': 9,
        \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
        \ 'text': 'Evaluate',
        \ }), l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 5,
        \ 'col': 9,
        \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
        \ 'text': 'Redundant $',
        \ }), l:qflist)
endfunction

function! s:unit.test_lint_whitespace()
  edit test/data/with\ whitespace/src/Foo/Bar.hs
  let l:qflist = s:normalize(ghcmod#make('lint', expand('%:p')))
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 5,
        \ 'col': 9,
        \ 'filename': 'test/data/with whitespace/src/Foo/Bar.hs',
        \ 'text': 'Evaluate',
        \ }), l:qflist)
  call self.assert.any(s:make_qf_pred({
        \ 'lnum': 5,
        \ 'col': 9,
        \ 'filename': 'test/data/with whitespace/src/Foo/Bar.hs',
        \ 'text': 'Redundant $',
        \ }), l:qflist)
endfunction

function! s:unit.test_lint_async()
  edit test/data/with-cabal/src/Foo/Bar.hs
  let l:callback = { 'assert': self.assert }
  function! l:callback.on_finish(qflist)
    call s:normalize(a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 5,
          \ 'col': 9,
          \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
          \ 'text': 'Evaluate',
          \ }), a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 5,
          \ 'col': 9,
          \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
          \ 'text': 'Redundant $',
          \ }), a:qflist)
  endfunction
  call s:async(l:callback)
endfunction

function! s:unit.test_lint_opt()
  let g:ghcmod_hlint_options = ['-i', 'Evaluate']
  try
    edit test/data/with-cabal/src/Foo/Bar.hs
    let l:qflist = s:normalize(ghcmod#make('lint', expand('%:p')))
    call self.assert.none(s:make_qf_pred({ 'text': 'Evaluate' }), l:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 5,
          \ 'col': 9,
          \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
          \ 'text': 'Redundant $',
          \ }), l:qflist)
  finally
    unlet g:ghcmod_hlint_options
  endtry
endfunction

function! s:unit.test_lint_async_opt()
  let g:ghcmod_hlint_options = ['-i', 'Evaluate']
  edit test/data/with-cabal/src/Foo/Bar.hs
  let l:callback = { 'assert': self.assert }
  function! l:callback.on_finish(qflist)
    unlet g:ghcmod_hlint_options
    call s:normalize(a:qflist)
    call self.assert.none(s:make_qf_pred({ 'text': 'Evaluate' }), a:qflist)
    call self.assert.any(s:make_qf_pred({
          \ 'lnum': 5,
          \ 'col': 9,
          \ 'filename': 'test/data/with-cabal/src/Foo/Bar.hs',
          \ 'text': 'Redundant $',
          \ }), a:qflist)
  endfunction
  call s:async(l:callback)
endfunction

call s:unit.run()
