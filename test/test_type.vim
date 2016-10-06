let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_type()
  edit test/data/with-cabal/src/Foo.hs
  let l:types = ghcmod#type(4, 7, expand('%:p'))
  call self.assert.equal([
        \ [[4, 7, 4, 10], '[Char]'],
        \ [[4, 7, 4, 16], '[Char]'],
        \ [[4, 1, 4, 16], '[Char]'],
        \ ], l:types)
endfunction

function! s:unit.test_type_compilation_failure()
  edit test/data/failure/Main.hs
  let l:types = ghcmod#type(4, 7, expand('%:p'))
  call self.assert.empty(l:types)
endfunction

function! s:unit.test_kill_recovery()
  call s:unit.test_type()
  call ghcmod#kill_modi(9)
  call s:unit.test_type()
endfunction

call s:unit.run()
