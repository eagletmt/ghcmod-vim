let s:outputs = []

function! s:check(line, col)
  call add(s:outputs, string(ghcmod#type(a:line, a:col, expand('%:p'), ghcmod#detect_module())))
endfunction

function! s:main()
  edit test/data/with-cabal/src/Foo.hs
  call s:check(4, 7)

  edit test/data/failure/Main.hs
  call s:check(5, 1)

  call writefile(s:outputs, 'test/output/type.out')
endfunction

call s:main()
