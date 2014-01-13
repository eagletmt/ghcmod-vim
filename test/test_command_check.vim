let s:unit = tinytest#new()

function! s:unit.teardown()
  unlet! g:ghcmod_open_quickfix_function
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

function! s:unit.test_quickfix_function()
  let g:ghcmod_open_quickfix_function = 'TestQuickfixFunction'
  edit test/data/with-cabal/src/Foo.hs
  let l:bufnr = bufnr('%')
  let s:qf_list = []
  GhcModCheck
  call self.assert.equal(l:bufnr, bufnr('%'))
  call self.assert.equal(getqflist(), s:qf_list)
  call self.assert.equal(2, len(s:qf_list))
endfunction

function! s:unit.test_quickfix_function_no_error()
  let g:ghcmod_open_quickfix_function = 'TestQuickfixFunction'
  edit test/data/without-cabal/Foo/Bar.hs
  let l:bufnr = bufnr('%')
  let s:qf_list = ['garbage']
  GhcModCheck
  call self.assert.equal(l:bufnr, bufnr('%'))
  call self.assert.equal(getqflist(), s:qf_list)
  call self.assert.empty(s:qf_list)
endfunction

function! TestQuickfixFunction()
  let s:qf_list = getqflist()
endfunction

call s:unit.run()
