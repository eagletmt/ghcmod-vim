let s:outputs = []

function! s:check(fexp, regexp)
  let l:x = ghcmod#info(a:fexp, expand('%:p'), ghcmod#detect_module())
  if l:x =~# a:regexp
    call add(s:outputs, 'OK')
  else
    " Avoid NUL character
    call add(s:outputs, substitute(l:x, '\n', '@', 'g'))
  endif
endfunction

function! s:main()
  edit test/data/with-cabal/src/Foo.hs
  call s:check('bar', '^bar :: \[Char\]')

  edit test/data/failure/Main.hs
  call s:check('main', '^Error:')

  call writefile(s:outputs, 'test/output/info.out')
endfunction

call s:main()
