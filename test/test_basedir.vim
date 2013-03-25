let s:outputs = []

function! s:write()
  " normalize path
  call add(s:outputs, fnamemodify(ghcmod#basedir(), ':.'))
endfunction

function! s:without_cabal()
  edit test/data/without-cabal/Main.hs
  call s:write()
  edit test/data/without-cabal/Foo/Bar.hs
  call s:write()
endfunction

function! s:with_cabal()
  edit test/data/with-cabal/src/Foo.hs
  call s:write()
  edit test/data/with-cabal/src/Foo/Bar.hs
  call s:write()
endfunction

function! s:main()
  call s:without_cabal()
  call s:with_cabal()

  let g:ghcmod_use_basedir = 'test/data'
  call s:without_cabal()
  call s:with_cabal()

  call writefile(s:outputs, 'test/output/basedir.out')
endfunction

call s:main()
