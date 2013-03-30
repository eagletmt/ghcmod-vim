function! s:build()
  return map(ghcmod#build_command(['do']), 'fnamemodify(v:val, ":.")')
endfunction

let s:unit = tinytest#new()

function! s:unit.teardown()
  bdelete
endfunction

function! s:unit.test_build()
  edit test/data/without-cabal/Foo/Bar.hs
  call self.assert.equal(['ghc-mod', 'do'], s:build())
endfunction

function! s:unit.test_build_with_dist_dir()
  try
    call system('cd test/data/with-cabal; cabal configure; cabal build')
    edit test/data/with-cabal/src/Foo/Bar.hs
    call self.assert.equal(['ghc-mod',
          \ '-g', '-i', '-g', 'test/data/with-cabal/dist/build/autogen',
          \ '-g', '-I', '-g', 'test/data/with-cabal/dist/build/autogen',
          \ '-g', '-optP-include',
          \ '-g', '-optP', '-g', 'test/data/with-cabal/dist/build/autogen/cabal_macros.h',
          \ '-g', '-i', '-g', 'test/data/with-cabal/dist/build',
          \ '-g', '-I', '-g', 'test/data/with-cabal/dist/build',
          \ 'do'], s:build())
  finally
    call system('cd test/data/with-cabal; rm -rf dist')
  endtry
endfunction

function! s:unit.test_build_global_opt()
  let g:ghcmod_ghc_options = ['-Wall']
  try
    edit test/data/without-cabal/Main.hs
    call self.assert.equal(['ghc-mod', '-g', '-Wall', 'do'], s:build())
  finally
    unlet g:ghcmod_ghc_options
  endtry
endfunction

function! s:unit.test_build_buffer_opt()
  " If b:ghcmod_ghc_options is set, g:ghcmod_ghc_options is ignored
  edit test/data/without-cabal/Foo/Bar.hs
  let g:ghcmod_ghc_options = ['-Wall']
  try
    let b:ghcmod_ghc_options = ['-W']
    call self.assert.equal(['ghc-mod', '-g', '-W', 'do'], s:build())
  finally
    unlet g:ghcmod_ghc_options
  endtry
endfunction

call s:unit.run()
