let s:outputs = []

function! s:write()
  call extend(s:outputs, map(ghcmod#build_command(['do']), 'fnamemodify(v:val, ":.")'))
  call add(s:outputs, '######')
endfunction

function! s:main()
  edit test/data/without-cabal/Main.hs
  call s:write()

  edit test/data/with-cabal/src/Foo.hs
  call s:write()

  edit test/data/with-cabal/src/Foo.hs
  try
    call system('cd test/data/with-cabal; cabal configure; cabal build')
    call s:write()
  finally
    call system('cd test/data/with-cabal; rm -rf dist')
  endtry

  let g:ghcmod_ghc_options = ['-Wall']
  edit test/data/without-cabal/Main.hs
  call s:write()

  " If b:ghcmod_ghc_options is set, g:ghcmod_ghc_options is ignored
  edit test/data/without-cabal/Main.hs
  let g:ghcmod_ghc_options = ['-Wall']
  let b:ghcmod_ghc_options = ['-W']
  call s:write()

  call writefile(s:outputs, 'test/output/build_command.out')
endfunction

call s:main()
