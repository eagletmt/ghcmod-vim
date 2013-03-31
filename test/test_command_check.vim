let s:unit = tinytest#new()

function! s:unit.teardown()
  cclose
  bdelete
endfunction

function! s:unit.test_command_check()
  edit test/data/with-cabal/src/Foo.hs
  call self.assert.exist(':GhcModCheck')
  GhcModCheck
  call self.assert.equal('quickfix', &buftype)
  call self.assert.equal(2, len(getqflist()))
endfunction

function! s:unit.test_command_check_no_error()
  edit test/data/without-cabal/Foo/Bar.hs
  call self.assert.exist(':GhcModCheck')
  let l:bufnr = bufnr('%')
  GhcModCheck
  call self.assert.not_equal('quickfix', &buftype)
  call self.assert.equal(l:bufnr, bufnr('%'))
endfunction

call s:unit.run()
