function! s:basedir()
  " normalize path
  return fnamemodify(ghcmod#basedir(), ':.')
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_with_cabal()
  edit test/data/with-cabal/src/Foo.hs
  call self.assert.equal('test/data/with-cabal', s:basedir())
endfunction

function! s:unit.test_with_cabal_subdir()
  edit test/data/with-cabal/src/Foo/Bar.hs
  call self.assert.equal('test/data/with-cabal', s:basedir())
endfunction

function! s:unit.test_without_cabal()
  edit test/data/without-cabal/Main.hs
  call self.assert.equal('test/data/without-cabal', s:basedir())
endfunction

function! s:unit.test_without_cabal_subdir()
  edit test/data/without-cabal/Foo/Bar.hs
  call self.assert.equal('test/data/without-cabal/Foo', s:basedir())
endfunction

function! s:unit.test_with_cabal_opt()
  let g:ghcmod_use_basedir = 'test/data'
  try
    edit test/data/with-cabal/src/Foo/Bar.hs
    call self.assert.equal(g:ghcmod_use_basedir, s:basedir())
  finally
    unlet g:ghcmod_use_basedir
  endtry
endfunction

function! s:unit.test_without_cabal_opt()
  let g:ghcmod_use_basedir = 'test/data'
  try
    edit test/data/without-cabal/Foo/Bar.hs
    call self.assert.equal(g:ghcmod_use_basedir, s:basedir())
  finally
    unlet g:ghcmod_use_basedir
  endtry
endfunction

call s:unit.run()
