function! s:info(fexp)
  return ghcmod#info(a:fexp, expand('%:p'), ghcmod#detect_module())
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_info()
  edit test/data/with-cabal/src/Foo.hs
  call self.assert.match('^bar :: \[Char\]', s:info('bar'))
endfunction

function! s:unit.test_info_syntax_error()
  edit test/data/failure/SyntaxError.hs
  call self.assert.match('^Cannot show info', s:info('main'))
endfunction

call s:unit.run()
